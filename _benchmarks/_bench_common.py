#!/usr/bin/env python3
"""Shared helpers for the _benchmarks/ suite (zsh / neovim / pi).

Stdlib only — no third-party deps, consistent with the repo's "minimise
external dependencies" stance. This module is the single home for everything
the three benchmark scripts used to duplicate:

* TTY-aware color (auto-disabled for pipes / NO_COLOR / dumb terminals),
* the ``▶`` / ``⚠`` glyph helpers,
* statistics (``percentile`` / ``summarize`` / the ``Stats`` dataclass),
* a uniform ASCII table renderer with a highlighted headline column,
* a hyperfine-style outlier/quality note,
* a PTY runner (consolidates the neovim + pi PTY logic, with a consistent
  ``start_new_session`` + ``killpg`` teardown and an interactive variant),
* NaN-safe JSON writing, and argparse validators / a ``--color`` flag.

Each script imports it via a 2-line prologue (there is no package / runner)::

    import sys; from pathlib import Path
    sys.path.insert(0, str(Path(__file__).resolve().parent))
    import _bench_common as bench
"""

from __future__ import annotations

import argparse
import json
import math
import os
import pty
import re
import select
import signal
import statistics
import subprocess
import sys
import threading
import time
from dataclasses import dataclass, field, asdict
from pathlib import Path
from typing import Any, Callable, Sequence

# --------------------------------------------------------------------------- #
# Color
# --------------------------------------------------------------------------- #

# Palette mirrors _scripts/colors.sh so colored Python output sits next to the
# repo's colored shell output without clashing.
_CODES = {
    "BOLD": "\033[1m",
    "DIM": "\033[2m",
    "RED": "\033[31m",
    "GREEN": "\033[32m",
    "YELLOW": "\033[33m",
    "CYAN": "\033[36m",
    "MAGENTA": "\033[35m",
    "RESET": "\033[0m",
}


def should_color(stream: Any = None, *, force: bool | None = None) -> bool:
    """Decide whether to emit ANSI color for ``stream``.

    ``force`` (from ``--color`` / ``--no-color``) wins. Otherwise: honor the
    ``NO_COLOR`` convention, never color a ``dumb`` terminal, and only color a
    real TTY (so pipes, files, and CI stay clean).
    """
    if force is not None:
        return force
    if os.environ.get("NO_COLOR"):
        return False
    if os.environ.get("TERM") == "dumb":
        return False
    stream = stream if stream is not None else sys.stdout
    try:
        return bool(stream.isatty())
    except Exception:
        return False


class Palette:
    """ANSI color codes, blanked out when color is disabled."""

    __slots__ = ("enabled", "BOLD", "DIM", "RED", "GREEN", "YELLOW", "CYAN",
                 "MAGENTA", "RESET")

    def __init__(self, enabled: bool) -> None:
        self.enabled = enabled
        for name, code in _CODES.items():
            setattr(self, name, code if enabled else "")

    def wrap(self, text: str, *codes: str) -> str:
        if not self.enabled or not codes:
            return text
        return "".join(codes) + text + self.RESET

    def bold(self, text: str) -> str:
        return self.wrap(text, self.BOLD)

    def dim(self, text: str) -> str:
        return self.wrap(text, self.DIM)

    def green(self, text: str) -> str:
        return self.wrap(text, self.GREEN)

    def cyan(self, text: str) -> str:
        return self.wrap(text, self.CYAN)

    def yellow(self, text: str) -> str:
        return self.wrap(text, self.YELLOW)

    def red(self, text: str) -> str:
        return self.wrap(text, self.RED)

    def magenta(self, text: str) -> str:
        return self.wrap(text, self.MAGENTA)


def make_palette(args: argparse.Namespace | None = None, stream: Any = None) -> Palette:
    force = getattr(args, "color", None) if args is not None else None
    return Palette(should_color(stream, force=force))


def add_color_args(parser: argparse.ArgumentParser) -> None:
    """Add a mutually-exclusive ``--color`` / ``--no-color`` pair (default auto)."""
    g = parser.add_mutually_exclusive_group()
    g.add_argument("--color", dest="color", action="store_true", default=None,
                   help="force color output even when not a TTY")
    g.add_argument("--no-color", dest="color", action="store_false",
                   help="disable color output")


# --------------------------------------------------------------------------- #
# Glyph helpers — keep the ▶ / ⚠ aesthetic the scripts already use
# --------------------------------------------------------------------------- #

def header(name: str, desc: str, pal: Palette) -> str:
    """A scenario header line: ``▶ name  (desc)`` (name bold when colored)."""
    return f"▶ {pal.bold(name)}  ({desc})"


def warn(msg: str, *, pal: Palette | None = None) -> None:
    """Print an operational ``⚠`` warning to stderr (yellow on a TTY)."""
    pal = pal or make_palette(stream=sys.stderr)
    print(pal.yellow(f"⚠ {msg}"), file=sys.stderr, flush=True)


# --------------------------------------------------------------------------- #
# Statistics
# --------------------------------------------------------------------------- #

@dataclass
class Stats:
    """The canonical reported metric set (median is the headline)."""
    n: int
    mean: float
    median: float
    min: float
    max: float
    p95: float
    stdev: float
    cv: float  # coefficient of variation, percent
    samples: list[float] = field(default_factory=list)

    def to_dict(self) -> dict[str, Any]:
        return asdict(self)


def percentile(samples: Sequence[float], pct: float) -> float:
    """Linear-interpolation percentile (matches numpy.percentile default).

    Sorts internally, so any input order is safe (the sample counts here are in
    the tens, so the O(n log n) cost is irrelevant). Returns NaN only for an
    empty sequence (callers that may pass empty should guard, and ``write_json``
    sanitizes NaN anyway).
    """
    n = len(samples)
    if n == 0:
        return float("nan")
    s = sorted(samples)
    if n == 1:
        return float(s[0])
    k = (n - 1) * (pct / 100.0)
    lo = math.floor(k)
    hi = math.ceil(k)
    if lo == hi:
        return float(s[int(k)])
    return s[lo] + (s[hi] - s[lo]) * (k - lo)


def summarize(samples: Sequence[float]) -> Stats | None:
    """Summarize raw ms samples; ``None`` for an empty input.

    CV is forced to 0.0 (not NaN) when the mean is 0 so JSON stays valid and
    the number reads sensibly. ``samples`` is copied to avoid aliasing the
    caller's list.
    """
    if not samples:
        return None
    ss = sorted(samples)
    n = len(ss)
    mean = statistics.fmean(ss)
    sd = statistics.stdev(ss) if n > 1 else 0.0
    cv = (sd / mean * 100.0) if mean else 0.0
    return Stats(
        n=n,
        mean=mean,
        median=statistics.median(ss),
        min=ss[0],
        max=ss[-1],
        p95=percentile(ss, 95),
        stdev=sd,
        cv=cv,
        samples=list(samples),
    )


def outlier_note(stats: Stats | None, *, label: str = "", cv_threshold: float = 5.0,
                 mad_mult: float = 5.0) -> str | None:
    """hyperfine-style quality flag, or ``None`` if the run looks clean.

    Flags high relative variance (CV) and a slow outlier run (max far from the
    median in median-absolute-deviation units — the robust estimator hyperfine
    itself uses). Returns the message body (no glyph); callers render it.
    """
    if stats is None or stats.n < 2:
        return None
    reasons: list[str] = []
    if stats.cv > cv_threshold:
        reasons.append(f"high variance (CV {stats.cv:.1f}%)")
    deviations = [abs(x - stats.median) for x in stats.samples]
    mad = statistics.median(deviations) if deviations else 0.0
    if mad > 0 and (stats.max - stats.median) > mad_mult * mad:
        reasons.append("a slow outlier run")
    if not reasons:
        return None
    where = f" in '{label}'" if label else ""
    return f"{' and '.join(reasons)}{where} — consider re-running on a quiet system"


# Canonical column set shared across all three scripts.
STAT_HEADERS = ["n", "median", "mean", "min", "p95", "σ", "CV"]
STAT_ALIGNS = ["r", "r", "r", "r", "r", "r", "r"]


def fmt_ms(value: float) -> str:
    return f"{value:.2f}"


def fmt_cv(value: float) -> str:
    return f"{value:.1f}%"


def stat_cells(stats: Stats) -> list[str]:
    """Format a Stats into the canonical ``STAT_HEADERS`` cells."""
    return [
        str(stats.n),
        fmt_ms(stats.median),
        fmt_ms(stats.mean),
        fmt_ms(stats.min),
        fmt_ms(stats.p95),
        fmt_ms(stats.stdev),
        fmt_cv(stats.cv),
    ]


# Definitions of the shared metric columns, shown in each script's Legend so the
# reader is reminded what each number means and which one to trust.
_BASE_LEGEND: list[tuple[str, str]] = [
    ("median", "middle value — the headline; robust to outliers"),
    ("mean", "arithmetic average; sensitive to outliers"),
    ("min", "fastest run — the noise floor / best achievable"),
    ("p95", "95th percentile — the slow tail (19 of 20 runs are faster)"),
    ("σ", "standard deviation — absolute spread of the samples"),
    ("CV", "σ / mean — relative spread; a low CV means a clean, trustworthy run"),
    ("n", "number of measured samples"),
]


def legend(extra: Sequence[tuple[str, str]] = (), *, pal: Palette | None = None,
           base: bool = True) -> str:
    """Render a 'Legend' section defining the metric/term vocabulary.

    ``extra`` adds domain-specific (term, definition) pairs after the shared
    metric definitions; pass ``base=False`` to show only ``extra``.
    """
    pal = pal or Palette(False)
    terms = [*_BASE_LEGEND, *extra] if base else list(extra)
    width = max((len(t) for t, _ in terms), default=0)
    lines = [pal.bold("Legend")]
    lines.extend(f"  {pal.cyan(term.ljust(width))}  {desc}" for term, desc in terms)
    return "\n".join(lines)


# --------------------------------------------------------------------------- #
# Table rendering — one renderer, used by every script
# --------------------------------------------------------------------------- #

def render_table(
    headers: Sequence[str],
    rows: Sequence[Sequence[Any]],
    *,
    aligns: Sequence[str] | None = None,
    highlight: int | str | None = None,
    pal: Palette | None = None,
    title: str | None = None,
) -> str:
    """Render a uniform ASCII table.

    ``aligns`` is per-column ``"l"`` / ``"r"`` (default left). ``highlight`` is
    a header name or index whose data cells are colored (the headline metric).
    ``title`` adds a bold title with an ``=`` rule above the table.
    """
    pal = pal or Palette(False)
    ncols = len(headers)
    # Tolerate a short/long aligns list rather than IndexError mid-render.
    aligns = (list(aligns) + ["l"] * ncols)[:ncols] if aligns is not None else ["l"] * ncols
    str_rows = [[str(c) for c in row] for row in rows]

    hi: int | None
    if isinstance(highlight, str):
        hi = headers.index(highlight) if highlight in headers else None
    else:
        hi = highlight

    # Widths use VISIBLE length (ANSI codes are zero-width) so a cell that
    # already contains color does not inflate the column or the separator.
    def vis(s: str) -> int:
        return len(strip_ansi(s))

    widths = []
    for i in range(ncols):
        cell_widths = [vis(r[i]) for r in str_rows] if str_rows else []
        widths.append(max(vis(str(headers[i])), *cell_widths) if cell_widths
                      else vis(str(headers[i])))

    def fmt_cell(text: str, i: int, *, is_header: bool) -> str:
        gap = max(0, widths[i] - vis(text))  # pad by visible width, ANSI-aware
        pad = (" " * gap + text) if aligns[i] == "r" else (text + " " * gap)
        if is_header:
            return pal.bold(pad)
        if i == hi:
            return pal.green(pad)
        return pad

    lines: list[str] = []
    if title:
        lines.append(pal.bold(title))
        lines.append("=" * len(title))
    lines.append("  ".join(fmt_cell(str(h), i, is_header=True)
                           for i, h in enumerate(headers)))
    lines.append("  ".join("-" * w for w in widths))
    for r in str_rows:
        lines.append("  ".join(fmt_cell(c, i, is_header=False)
                               for i, c in enumerate(r)))
    return "\n".join(lines)


# --------------------------------------------------------------------------- #
# ANSI stripping (for parsing captured subprocess output)
# --------------------------------------------------------------------------- #

ANSI_RE = re.compile(r"\x1B(?:[@-Z\\-_]|\[[0-?]*[ -/]*[@-~]|\][^\a]*(?:\a|\x1b\\))")


def strip_ansi(text: str) -> str:
    return ANSI_RE.sub("", text)


# --------------------------------------------------------------------------- #
# Version detection
# --------------------------------------------------------------------------- #

def tool_version(argv: list[str]) -> str:
    """Return the first line of ``argv`` output (e.g. ``[bin, "--version"]``).

    Raises RuntimeError if the binary is missing or exits non-zero; callers
    decide whether to exit.
    """
    try:
        out = subprocess.run(argv, stdout=subprocess.PIPE, stderr=subprocess.PIPE,
                             check=True)
    except (FileNotFoundError, subprocess.CalledProcessError) as e:
        raise RuntimeError(f"cannot run '{' '.join(argv)}': {e}") from e
    text = out.stdout.decode("utf-8", "replace") or out.stderr.decode("utf-8", "replace")
    lines = text.splitlines()
    return lines[0] if lines else ""


# --------------------------------------------------------------------------- #
# NaN-safe JSON
# --------------------------------------------------------------------------- #

def _sanitize(obj: Any) -> Any:
    """Replace NaN / ±Inf floats with None so output is valid JSON.

    ``json.dumps`` otherwise emits the barewords ``NaN`` / ``Infinity``, which
    jq and Node's ``JSON.parse`` both reject.
    """
    if isinstance(obj, float):
        return obj if math.isfinite(obj) else None
    if isinstance(obj, dict):
        return {k: _sanitize(v) for k, v in obj.items()}
    if isinstance(obj, (list, tuple)):
        return [_sanitize(v) for v in obj]
    return obj


def write_json(path: str | Path, obj: Any, *, sort_keys: bool = False) -> str:
    text = json.dumps(_sanitize(obj), indent=2, sort_keys=sort_keys, allow_nan=False)
    Path(path).write_text(text, encoding="utf-8")
    return text


# --------------------------------------------------------------------------- #
# argparse validators
# --------------------------------------------------------------------------- #

def pos_int(value: str) -> int:
    n = int(value)
    if n <= 0:
        raise argparse.ArgumentTypeError("must be > 0")
    return n


def nonneg_int(value: str) -> int:
    n = int(value)
    if n < 0:
        raise argparse.ArgumentTypeError("must be >= 0")
    return n


def pos_float(value: str) -> float:
    f = float(value)
    if f <= 0:
        raise argparse.ArgumentTypeError("must be > 0")
    return f


def nonneg_float(value: str) -> float:
    f = float(value)
    if f < 0:
        raise argparse.ArgumentTypeError("must be >= 0")
    return f


# --------------------------------------------------------------------------- #
# PTY execution
# --------------------------------------------------------------------------- #

def terminate_group(proc: subprocess.Popen, *, grace: float = 2.0) -> None:
    """Terminate the child's process group and reap it.

    With ``grace > 0``: SIGTERM, wait up to ``grace`` seconds, then SIGKILL.
    With ``grace == 0``: SIGKILL immediately — right for throwaway measurement
    shells, since an *interactive* zsh ignores SIGTERM and would otherwise stall
    the full grace period on every teardown. Relies on ``start_new_session=True``
    (pgid == pid) so the whole tree is reaped, not just the direct child.
    """
    # Resolve the real PGID rather than assuming pid == pgid: stays correct even
    # if a caller ever forgets start_new_session=True.
    try:
        pgid = os.getpgid(proc.pid)
    except Exception:
        pgid = proc.pid  # already gone, or no getpgid (non-POSIX)

    def killpg(sig: int) -> bool | None:
        try:
            os.killpg(pgid, sig)
            return True
        except ProcessLookupError:
            return False  # already gone
        except Exception:
            return None  # killpg unsupported on this platform

    if grace > 0:
        sent = killpg(signal.SIGTERM)
        if sent is False:
            return
        if sent is None:
            proc.terminate()
        else:
            try:
                proc.wait(timeout=grace)
                return
            except subprocess.TimeoutExpired:
                pass

    if killpg(signal.SIGKILL) is None:
        proc.kill()
    try:
        proc.wait(timeout=2)
    except subprocess.TimeoutExpired:
        pass


@dataclass
class PtyRun:
    returncode: int | None
    timed_out: bool
    stdout: bytes
    stderr: bytes


def run_under_pty(
    cmd: list[str],
    *,
    cwd: Path | str | None = None,
    env: dict[str, str] | None = None,
    timeout: float = 30.0,
    capture_stdout: bool = True,
    set_winsize: tuple[int, int] | None = None,
) -> PtyRun:
    """Run ``cmd`` to completion attached to a PTY (so a TUI client attaches).

    stdin+stdout go to the PTY (drained by a thread); stderr is a separate pipe
    drained by ``communicate``. On timeout or KeyboardInterrupt the whole child
    process group is terminated (no orphans). ``set_winsize`` is ``(rows, cols)``.
    """
    master_fd, slave_fd = pty.openpty()
    if set_winsize is not None:
        _set_winsize(slave_fd, *set_winsize)
    chunks: list[bytes] = []
    stderr_data = b""
    timed_out = False
    proc: subprocess.Popen | None = None
    try:
        proc = subprocess.Popen(
            cmd,
            stdin=slave_fd,
            stdout=slave_fd,
            stderr=subprocess.PIPE,
            cwd=str(cwd) if cwd else None,
            env=env,
            close_fds=True,
            start_new_session=True,
        )
        os.close(slave_fd)
        slave_fd = -1

        def drain() -> None:
            while True:
                try:
                    data = os.read(master_fd, 8192)
                except OSError:
                    break
                if not data:
                    break
                if capture_stdout:
                    chunks.append(data)

        reader = threading.Thread(target=drain, daemon=True)
        reader.start()
        try:
            _, stderr_data = proc.communicate(timeout=timeout)
        except subprocess.TimeoutExpired:
            timed_out = True
            terminate_group(proc)
            try:
                _, stderr_data = proc.communicate(timeout=2)
            except subprocess.TimeoutExpired:
                proc.kill()
                try:
                    _, stderr_data = proc.communicate(timeout=2)
                except subprocess.TimeoutExpired:
                    stderr_data = b""
        except BaseException:
            # KeyboardInterrupt or anything else: don't leave an orphan.
            terminate_group(proc)
            raise
        finally:
            # Close master FIRST so a blocked drain() read hits EOF/OSError and
            # the thread finishes, THEN join uncapped so `chunks` is provably
            # final before b"".join() reads it below (no raced/partial capture).
            try:
                os.close(master_fd)
            except OSError:
                pass
            master_fd = -1
            reader.join()
    finally:
        if slave_fd >= 0:
            try:
                os.close(slave_fd)
            except OSError:
                pass
        if master_fd >= 0:
            try:
                os.close(master_fd)
            except OSError:
                pass

    return PtyRun(
        returncode=proc.returncode if proc is not None else None,
        timed_out=timed_out,
        stdout=b"".join(chunks),
        stderr=stderr_data or b"",
    )


def _set_winsize(fd: int, rows: int, cols: int) -> None:
    try:
        import fcntl
        import struct
        import termios

        fcntl.ioctl(fd, termios.TIOCSWINSZ, struct.pack("HHHH", rows, cols, 0, 0))
    except Exception:
        pass  # window size is nice-to-have only


class PtyProcess:
    """An interactive process on a PTY: write keystrokes, time when markers appear.

    Used to measure zsh time-to-interactive (first prompt / command lag) the way
    zsh-bench does — inject a sentinel, then read the PTY and timestamp when the
    sentinel shows up. All three of stdin/stdout/stderr go to the PTY slave.
    """

    def __init__(self, cmd: list[str], *, cwd: Path | str | None = None,
                 env: dict[str, str] | None = None,
                 winsize: tuple[int, int] | None = None) -> None:
        self.master_fd, slave_fd = pty.openpty()
        if winsize is not None:
            _set_winsize(slave_fd, *winsize)
        try:
            self.proc = subprocess.Popen(
                cmd,
                stdin=slave_fd,
                stdout=slave_fd,
                stderr=slave_fd,
                cwd=str(cwd) if cwd else None,
                env=env,
                close_fds=True,
                start_new_session=True,
            )
        finally:
            os.close(slave_fd)
        self.t0 = time.perf_counter()
        self.buf = bytearray()

    def write(self, data: bytes) -> None:
        os.write(self.master_fd, data)

    def read_until_count(self, pattern: bytes, count: int, timeout: float) -> float | None:
        """Block until ``pattern`` has appeared ``count`` times in cumulative
        output; return seconds since spawn at the read that reached ``count``,
        or ``None`` on timeout / EOF.
        """
        if self.buf.count(pattern) >= count:
            return time.perf_counter() - self.t0
        end = time.perf_counter() + timeout
        while True:
            remaining = end - time.perf_counter()
            if remaining <= 0:
                return None
            try:
                r, _, _ = select.select([self.master_fd], [], [], remaining)
            except OSError:
                return None
            if not r:
                return None
            try:
                data = os.read(self.master_fd, 4096)
            except OSError:
                return None  # EIO: child exited
            if not data:
                return None
            t = time.perf_counter()
            self.buf += data
            if self.buf.count(pattern) >= count:
                return t - self.t0

    def close(self) -> None:
        # grace=0: an interactive zsh ignores SIGTERM, so kill the throwaway
        # measurement shell immediately rather than stalling 2s per teardown.
        terminate_group(self.proc, grace=0.0)
        try:
            os.close(self.master_fd)
        except OSError:
            pass

    def __enter__(self) -> "PtyProcess":
        return self

    def __exit__(self, *exc: Any) -> None:
        self.close()
