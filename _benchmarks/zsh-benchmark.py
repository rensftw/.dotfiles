#!/usr/bin/env python3
"""zsh-benchmark.py — benchmark and profile Zsh startup.

Three complementary views, all dependency-free pure Python:

1. Exit-time (default) — statistical wall-clock timing of ``zsh <flags> -c
   exit``, mirroring hyperfine's methodology (warmup, then median/mean/p95/σ/CV
   over N runs). **This is a proxy, not interactivity**: ``-c exit`` runs
   immediately and never draws a prompt, so it does not reflect how responsive
   the shell *feels*. romkatv (powerlevel10k author) makes this point sharply in
   zsh-bench: "the output of ``time zsh -lic exit`` does not tell you anything
   about the performance of interactive zsh." Use it for cheap relative deltas
   (how much your .zshrc costs), then look at the next view.

2. Time-to-interactive (``--interactive``) — the metric that actually reflects
   responsiveness, ported from zsh-bench's methodology: drive a real interactive
   zsh under a PTY, inject a sentinel via a non-invasive ZDOTDIR shim, and time
   when the sentinel appears.
       first_prompt_lag  — spawn → first (fully-initialized) prompt is ready.
       first_command_lag — spawn → a command typed *immediately* actually runs.
       command_lag       — Enter on an empty line → next prompt (steady-state
                            felt responsiveness; zsh-bench's headline metric).
   Caveat: if your prompt uses an instant-prompt mechanism (e.g. powerlevel10k)
   it paints a prompt *before* full init, so the perceived first prompt can be
   earlier than first_prompt_lag here. oh-my-posh and most prompts do NOT do
   this, so for them first_prompt_lag is your true felt first-prompt time. For
   the gold-standard, instant-prompt-aware numbers, use upstream zsh-bench
   (github.com/romkatv/zsh-bench).

3. Profiling (``--profile``) — per-function attribution via zsh's built-in
   ``zprof`` module, the canonical way to find *what* is slow. A non-invasive
   ZDOTDIR shim loads zprof before sourcing your real .zshrc, then prints the
   report — your real config is never edited.

Each exit-time sample wall-clocks ``zsh <flags> -c exit`` with
``time.perf_counter()``; subprocess fork+exec adds ~1ms of fixed overhead
(consistent across samples, so deltas are accurate). This differs from
hyperfine, which runs commands under a shell wrapper and subtracts an
empty-shell baseline — we spawn zsh directly and leave the fork+exec in, so
compare medians/deltas here, never absolute ms against a hyperfine figure.

Scenarios (exit-time)
---------------------
1. ``bare``        — ``zsh -f -i -c exit`` (interactive, ``-f`` skips rc files;
                     the floor for your config).
2. ``interactive`` — ``zsh -i -c exit`` (sources .zshenv + .zshrc; the typical
                     new-tab experience).
3. ``login``       — ``zsh -l -i -c exit`` (also .zprofile + .zlogin; macOS
                     Terminal.app launches login shells by default).

OS page cache: the first sample after a cold boot is slower. Run ``sudo purge``
before the script for a page-cache-cold first sample (the macOS analogue of
Linux ``drop_caches``).

Usage
-----
    ./zsh-benchmark.py
    ./zsh-benchmark.py --runs 50 --warmup 5
    ./zsh-benchmark.py --interactive            # time-to-interactive metrics
    ./zsh-benchmark.py --scenario interactive
    ./zsh-benchmark.py --profile                # exit-time + zprof
    ./zsh-benchmark.py --profile --runs 0       # zprof only
    ./zsh-benchmark.py --json results.json
"""

from __future__ import annotations

import argparse
import os
import re
import subprocess
import sys
import tempfile
import time
from dataclasses import dataclass
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import _bench_common as bench  # noqa: E402

DEFAULT_RUNS = 20
DEFAULT_WARMUP = 3
DEFAULT_PROFILE_LINES = 15
DEFAULT_INTERACTIVE_ITERS = 10
DEFAULT_TIMEOUT_SEC = 15.0

# zprof's table header, e.g. "num  calls                time  ...  name"
_ZPROF_HEADER_RE = re.compile(r"^\s*num\s+calls\s+time")


@dataclass
class ScenarioResult:
    name: str
    description: str
    command: list[str]
    stats: bench.Stats | None


# --------------------------------------------------------------------------- #
# Exit-time benchmark
# --------------------------------------------------------------------------- #

def run_once(zsh_bin: str, flags: list[str], cwd: Path | None, timeout: float) -> float:
    """Run zsh once with given flags, return wall-clock ms."""
    cmd = [zsh_bin, *flags, "-c", "exit"]
    t0 = time.perf_counter()
    proc = subprocess.run(
        cmd,
        cwd=str(cwd) if cwd else None,
        stdin=subprocess.DEVNULL,
        stdout=subprocess.DEVNULL,
        stderr=subprocess.PIPE,
        timeout=timeout,
        check=False,
    )
    elapsed_ms = (time.perf_counter() - t0) * 1000.0
    if proc.returncode != 0:
        err = proc.stderr.decode("utf-8", errors="replace").strip()
        raise RuntimeError(
            f"zsh exited with code {proc.returncode}: {err or '(no stderr)'}\n"
            f"command: {' '.join(cmd)}"
        )
    return elapsed_ms


def bench_scenario(
    name: str,
    description: str,
    flags: list[str],
    zsh_bin: str,
    warmup: int,
    runs: int,
    cwd: Path | None,
    timeout: float,
    verbose: bool,
    quiet: bool,
    pal: bench.Palette,
) -> ScenarioResult:
    full_cmd = [zsh_bin, *flags, "-c", "exit"]
    if not quiet:
        print(
            f"\n{bench.header(name, description, pal)}\n"
            f"  command: {' '.join(full_cmd)}\n"
            f"  warmup: {warmup}, runs: {runs}",
            flush=True,
        )

    for i in range(warmup):
        t = run_once(zsh_bin, flags, cwd=cwd, timeout=timeout)
        if verbose:
            print(f"    warmup {i + 1:>2}: {t:7.2f} ms", flush=True)

    samples: list[float] = []
    if not quiet:
        print("  measuring ", end="", flush=True)
    t0 = time.perf_counter()
    for i in range(runs):
        t = run_once(zsh_bin, flags, cwd=cwd, timeout=timeout)
        samples.append(t)
        if verbose:
            print(f"\n    run {i + 1:>2}: {t:7.2f} ms", end="", flush=True)
        elif not quiet:
            print(".", end="", flush=True)
    if not quiet:
        print(f"  ({time.perf_counter() - t0:.1f}s)", flush=True)

    return ScenarioResult(
        name=name,
        description=description,
        command=full_cmd,
        stats=bench.summarize(samples),
    )


def format_exit_table(results: list[ScenarioResult], pal: bench.Palette) -> str:
    rows: list[list[str]] = []
    for r in results:
        if r.stats is None:
            continue
        rows.append([r.name, *bench.stat_cells(r.stats)])
    if not rows:
        return "(no samples collected)"

    headers = ["scenario", *bench.STAT_HEADERS]
    aligns = ["l", *bench.STAT_ALIGNS]
    table = bench.render_table(headers, rows, aligns=aligns,
                               highlight="median", pal=pal)
    lines = [table]

    # Deltas — most useful insight — computed from the MEDIAN (robust on the
    # right-skewed startup distribution; the mean is outlier-sensitive).
    by_name = {r.name: r.stats.median for r in results if r.stats is not None}
    deltas: list[str] = []
    if "bare" in by_name and "interactive" in by_name:
        d = by_name["interactive"] - by_name["bare"]
        deltas.append(f"  .zshrc overhead     ≈ {pal.cyan(f'{d:+.1f} ms')} "
                      f"(median: interactive − bare)")
    if "interactive" in by_name and "login" in by_name:
        d = by_name["login"] - by_name["interactive"]
        deltas.append(f"  .zprofile/.zlogin   ≈ {pal.cyan(f'{d:+.1f} ms')} "
                      f"(median: login − interactive)")
    if deltas:
        lines += ["", "Deltas:"] + deltas

    for r in results:
        note = bench.outlier_note(r.stats, label=r.name)
        if note:
            lines.append(pal.yellow(f"⚠ {note}"))

    lines += [
        "",
        "Wall clock via time.perf_counter() — the same primitive hyperfine uses,",
        "but WITHOUT its empty-shell calibration, so the ~1ms fork+exec is left in",
        "(compare deltas/medians here, not absolute ms vs a hyperfine figure).",
        "Exit-time is a PROXY — it never draws a",
        "prompt, so it does not reflect interactivity. Run --interactive for",
        "time-to-interactive (first_prompt_lag / command_lag), and --profile for",
        "per-function attribution (zprof).",
    ]
    return "\n".join(lines)


# --------------------------------------------------------------------------- #
# Time-to-interactive benchmark (zsh-bench methodology)
# --------------------------------------------------------------------------- #

_PROMPT_MARKER = b"ZBPROMPT"
_CMD_MARKER = b"ZBCMDDONE"


def _write_interactive_shim(tmpdir: Path, home: Path, real_zshrc: Path) -> None:
    """ZDOTDIR shim: chain the real env, source the real .zshrc, then add a
    precmd hook that prints a sentinel before each prompt (non-invasive)."""
    (tmpdir / ".zshenv").write_text(
        f'[[ -f "{home}/.zshenv" ]] && source "{home}/.zshenv"\n'
    )
    (tmpdir / ".zshrc").write_text(
        "\n".join([
            f'[[ -f "{real_zshrc}" ]] && source "{real_zshrc}"',
            "autoload -Uz add-zsh-hook 2>/dev/null",
            f"_zb_precmd() {{ builtin print -r -- {_PROMPT_MARKER.decode()} }}",
            "if (( $+functions[add-zsh-hook] )); then",
            "  add-zsh-hook precmd _zb_precmd",
            "else",
            "  precmd_functions+=(_zb_precmd)",
            "fi",
            "",
        ])
    )


def measure_interactive(
    zsh_bin: str,
    iters: int,
    warmup: int,
    timeout: float,
    cwd: Path | None,
    verbose: bool,
    quiet: bool,
    pal: bench.Palette,
) -> dict[str, bench.Stats | None]:
    """Measure first_prompt_lag / first_command_lag / command_lag (ms)."""
    home = Path.home()
    real_zshrc = home / ".zshrc"
    if not real_zshrc.exists():
        raise RuntimeError(f"no ~/.zshrc at {real_zshrc}; nothing to measure")

    first_prompt: list[float] = []
    command_lag: list[float] = []
    first_command: list[float] = []

    with tempfile.TemporaryDirectory(prefix="zb-interactive-") as tmp:
        tmpdir = Path(tmp)
        _write_interactive_shim(tmpdir, home, real_zshrc)
        env = {**os.environ, "ZDOTDIR": str(tmpdir)}

        def spawn() -> bench.PtyProcess:
            return bench.PtyProcess([zsh_bin, "-i"], cwd=cwd, env=env,
                                    winsize=(40, 120))

        if not quiet:
            print(f"\n{bench.header('interactive', 'time-to-interactive, zsh-bench style', pal)}\n"
                  f"  warmup: {warmup}, iters: {iters}\n"
                  "  measuring ", end="", flush=True)
        t0 = time.perf_counter()

        # Warmup: a few discarded interactive starts to fill caches.
        for _ in range(warmup):
            p = spawn()
            try:
                p.read_until_count(_PROMPT_MARKER, 1, timeout)
            finally:
                p.close()

        # first_prompt_lag + command_lag share a shell per iteration.
        for _ in range(iters):
            p = spawn()
            try:
                t1 = p.read_until_count(_PROMPT_MARKER, 1, timeout)
                if t1 is None:
                    continue
                first_prompt.append(t1 * 1000.0)
                p.write(b"\r")  # Enter on an empty command line
                t2 = p.read_until_count(_PROMPT_MARKER, 2, timeout)
                if t2 is not None:
                    command_lag.append((t2 - t1) * 1000.0)
            finally:
                p.close()
            if not quiet and not verbose:
                print(".", end="", flush=True)

        # first_command_lag: type a command immediately, before the first
        # prompt. The marker is built from a variable ($m) so the echoed input
        # never contains the contiguous output marker (which would otherwise let
        # us time the echo instead of the command's execution).
        for _ in range(iters):
            p = spawn()
            try:
                p.write(b"m=DONE; builtin print -r -- ZBCMD$m\r")
                t = p.read_until_count(_CMD_MARKER, 1, timeout)
                if t is not None:
                    first_command.append(t * 1000.0)
            finally:
                p.close()
            if not quiet and not verbose:
                print(".", end="", flush=True)

        if not quiet:
            print(f"  ({time.perf_counter() - t0:.1f}s)", flush=True)

    return {
        "first_prompt_lag": bench.summarize(first_prompt),
        "first_command_lag": bench.summarize(first_command),
        "command_lag": bench.summarize(command_lag),
    }


def format_interactive_table(metrics: dict[str, bench.Stats | None],
                             pal: bench.Palette) -> str:
    order = ["first_prompt_lag", "first_command_lag", "command_lag"]
    rows: list[list[str]] = []
    for name in order:
        s = metrics.get(name)
        if s is None:
            continue
        rows.append([name, *bench.stat_cells(s)])
    if not rows:
        return "(no interactive samples collected — did the prompt render?)"

    headers = ["metric", *bench.STAT_HEADERS]
    aligns = ["l", *bench.STAT_ALIGNS]
    lines = [bench.render_table(headers, rows, aligns=aligns,
                                highlight="median", pal=pal)]
    for name in order:
        note = bench.outlier_note(metrics.get(name), label=name)
        if note:
            lines.append(pal.yellow(f"⚠ {note}"))
    lines += [
        "",
        "All times in ms, measured under a PTY (zsh-bench methodology). command_lag",
        "is the everyday 'does the shell feel sluggish' metric and the most",
        "reliable here; absolute first_prompt_lag can be inflated by terminal",
        "capability queries a real emulator would answer instantly. (If your",
        "prompt has an instant-prompt mechanism like powerlevel10k it paints",
        "before full init; oh-my-posh and most prompts do not.) For",
        "gold-standard numbers see upstream zsh-bench (github.com/romkatv/zsh-bench).",
    ]
    return "\n".join(lines)


# --------------------------------------------------------------------------- #
# zprof profiling
# --------------------------------------------------------------------------- #

def profile_zsh(zsh_bin: str, top_n: int, cwd: Path | None, timeout: float) -> str:
    """Run an interactive zsh under zprof via a non-invasive ZDOTDIR shim."""
    home = Path.home()
    real_zshrc = home / ".zshrc"
    if not real_zshrc.exists():
        raise RuntimeError(f"no ~/.zshrc at {real_zshrc}; nothing to profile")

    with tempfile.TemporaryDirectory(prefix="zprof-zdotdir-") as tmp:
        tmpdir = Path(tmp)
        (tmpdir / ".zshenv").write_text(
            f'[[ -f "{home}/.zshenv" ]] && source "{home}/.zshenv"\n'
        )
        (tmpdir / ".zshrc").write_text(
            f'zmodload zsh/zprof\nsource "{real_zshrc}"\nzprof\n'
        )
        proc = subprocess.run(
            [zsh_bin, "-i", "-c", "exit"],
            cwd=str(cwd) if cwd else None,
            stdin=subprocess.DEVNULL,
            stdout=subprocess.PIPE,
            stderr=subprocess.DEVNULL,
            env={**os.environ, "ZDOTDIR": str(tmpdir)},
            timeout=timeout,
            check=False,
        )

    out = proc.stdout.decode("utf-8", errors="replace").splitlines()
    # Isolate the zprof table; skip any MOTD/.zshrc chatter printed before it.
    start = next(
        (i for i, line in enumerate(out) if _ZPROF_HEADER_RE.match(line)), None
    )
    if start is None:
        raise RuntimeError(
            "zprof produced no table; is the zsh/zprof module available?"
        )
    # header + separator + top_n data rows
    return "\n".join(out[start:start + top_n + 2])


# --------------------------------------------------------------------------- #
# CLI
# --------------------------------------------------------------------------- #

SCENARIOS: dict[str, tuple[str, list[str]]] = {
    "bare":        ("interactive zsh, no rc files (-f)",     ["-f", "-i"]),
    "interactive": ("interactive zsh, sources .zshrc",       ["-i"]),
    "login":       ("login interactive zsh, full rc chain",  ["-l", "-i"]),
}


def parse_args() -> argparse.Namespace:
    p = argparse.ArgumentParser(
        description="Benchmark Zsh startup time.",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog=(
            "Examples:\n"
            "  %(prog)s\n"
            "  %(prog)s --runs 50 --warmup 5\n"
            "  %(prog)s --interactive\n"
            "  %(prog)s --scenario interactive\n"
            "  %(prog)s --json results.json --verbose\n"
        ),
    )
    p.add_argument("-r", "--runs", type=int, default=DEFAULT_RUNS,
                   help=f"exit-time iterations per scenario (default: {DEFAULT_RUNS})")
    p.add_argument("-w", "--warmup", type=int, default=DEFAULT_WARMUP,
                   help=f"warmup iterations, not counted (default: {DEFAULT_WARMUP})")
    p.add_argument("-s", "--scenario",
                   choices=[*SCENARIOS.keys(), "all"], default="all",
                   help="which exit-time scenario to run (default: all)")
    p.add_argument("-I", "--interactive", action="store_true",
                   help="also measure time-to-interactive (first_prompt_lag, "
                        "first_command_lag, command_lag) under a PTY, zsh-bench style")
    p.add_argument("--interactive-iters", type=bench.pos_int,
                   default=DEFAULT_INTERACTIVE_ITERS, metavar="N",
                   help=f"iterations for --interactive (default: {DEFAULT_INTERACTIVE_ITERS})")
    p.add_argument("-p", "--profile", action="store_true",
                   help="also run zprof and show top per-function offenders")
    p.add_argument("--profile-lines", type=bench.pos_int, default=DEFAULT_PROFILE_LINES,
                   metavar="N",
                   help=f"zprof rows to show with --profile (default: {DEFAULT_PROFILE_LINES})")
    p.add_argument("--zsh", default=os.environ.get("ZSH_BIN", "zsh"),
                   help="path to zsh binary (default: zsh, or $ZSH_BIN)")
    p.add_argument("--cwd", type=Path, default=None,
                   help="working directory to run zsh from")
    p.add_argument("--timeout", type=bench.pos_float, default=DEFAULT_TIMEOUT_SEC,
                   metavar="SEC", help=f"per-run timeout (default: {DEFAULT_TIMEOUT_SEC})")
    p.add_argument("--json", type=Path, default=None, metavar="PATH",
                   help="also write results to PATH as JSON")
    p.add_argument("-v", "--verbose", action="store_true",
                   help="print each sample's timing")
    p.add_argument("-q", "--quiet", action="store_true",
                   help="suppress per-run progress output")
    bench.add_color_args(p)
    return p.parse_args()


def main() -> int:
    args = parse_args()
    if args.runs < 0:
        sys.exit("error: --runs must be >= 0")
    if args.runs == 0 and not (args.profile or args.interactive):
        sys.exit("error: --runs 0 only makes sense with --profile or --interactive")
    if args.warmup < 0:
        sys.exit("error: --warmup must be >= 0")

    pal = bench.make_palette(args)

    try:
        version_line = bench.tool_version([args.zsh, "--version"])
    except RuntimeError as e:
        sys.exit(f"error: {e}")
    print(f"Zsh:    {version_line}")
    print(f"Python: {sys.version.split()[0]}")
    print(f"CWD:    {args.cwd or Path.cwd()}")

    results: list[ScenarioResult] = []
    if args.runs > 0:
        selected = list(SCENARIOS.keys()) if args.scenario == "all" else [args.scenario]
        results = [
            bench_scenario(
                name=name,
                description=SCENARIOS[name][0],
                flags=SCENARIOS[name][1],
                zsh_bin=args.zsh,
                warmup=args.warmup,
                runs=args.runs,
                cwd=args.cwd,
                timeout=args.timeout,
                verbose=args.verbose,
                quiet=args.quiet,
                pal=pal,
            )
            for name in selected
        ]
        print("\n" + format_exit_table(results, pal))

    interactive: dict[str, bench.Stats | None] = {}
    if args.interactive:
        try:
            interactive = measure_interactive(
                args.zsh, args.interactive_iters, args.warmup, args.timeout,
                args.cwd, args.verbose, args.quiet, pal,
            )
            print("\n" + format_interactive_table(interactive, pal))
        except RuntimeError as e:
            bench.warn(f"interactive measurement failed: {e}")

    profile_output: str | None = None
    if args.profile:
        print(f"\n{bench.header('profile', 'zprof attribution for interactive .zshrc', pal)}",
              flush=True)
        try:
            profile_output = profile_zsh(args.zsh, args.profile_lines, args.cwd, args.timeout)
            print(profile_output)
            print(
                "\n'time' is cumulative (incl. called functions), 'self' excludes\n"
                "them. zprof instrumentation inflates absolute ms — read it for\n"
                "ranking, not wall-clock. compinit/compdump dominating is the\n"
                "classic cue to cache compinit (compinit -C + daily rebuild)."
            )
        except RuntimeError as e:
            bench.warn(f"profiling failed: {e}")

    if results or interactive:
        legend_extra: list[tuple[str, str]] = []
        if results:
            legend_extra.append(
                ("wall time", "process fork+exec → exit via perf_counter (~1ms overhead)"))
        if interactive:
            legend_extra += [
                ("first_prompt_lag", "spawn → first fully-initialized prompt is ready"),
                ("first_command_lag", "spawn → a command typed immediately actually runs"),
                ("command_lag", "Enter on an empty line → next prompt (felt responsiveness)"),
            ]
        print("\n" + bench.legend(legend_extra, pal=pal))

    if args.json:
        payload = {
            "zsh_version": version_line,
            "warmup": args.warmup,
            "runs": args.runs,
            "scenarios": [
                {
                    "name": r.name,
                    "description": r.description,
                    "command": r.command,
                    "stats": r.stats.to_dict() if r.stats else None,
                }
                for r in results
            ],
            "interactive": {
                k: (v.to_dict() if v else None) for k, v in interactive.items()
            } if interactive else None,
            "zprof": profile_output,
        }
        bench.write_json(args.json, payload)
        print(f"\nJSON written to {args.json}")

    return 0


if __name__ == "__main__":
    try:
        sys.exit(main())
    except KeyboardInterrupt:
        sys.exit(130)
    except (RuntimeError, subprocess.TimeoutExpired) as e:
        sys.exit(f"error: {e}")
