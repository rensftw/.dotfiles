#!/usr/bin/env python3
"""neovim-benchmark.py — benchmark Neovim startup time.

Each invocation parses ``nvim --startuptime <log>`` and reports the cumulative
ms at the ``--- NVIM STARTED ---`` line — the last line of the log, written
after VimEnter and UIEnter autocmds. Reference clock is the process ``exec()``.

To make the editor exit (without short-circuiting startup the way ``+qa!`` or
``--headless`` does — both make UIEnter never fire) the subprocess is given a
real PTY and a tiny autocmd::

    autocmd UIEnter * qa!

UIEnter fires once the TUI client has attached, by which point Neovim has done
the full startup work we want to measure. Using ``+qa!`` instead would emit
``--- NVIM STARTED ---`` early (~30ms instead of ~150ms on a typical config):
the bulk of that ~150ms is synchronous plugin/Lua initialization that only runs
once the TUI has attached, not UI attach itself (which is cheap, ~3ms). Driving
nvim under a PTY so UIEnter fires is the accepted technique (see lazy.nvim
discussion #1870, neovim #25377).

The PTY adds small overhead vs. a real terminal (capability queries real
emulators answer instantly). For the most faithful number, run ``nvim
--startuptime /tmp/log`` interactively in your normal terminal and read the last
line. For per-plugin attribution use ``:Lazy profile`` (the neovim analogue of
zprof) or ``rhysd/vim-startuptime``.

Scenarios
---------
1. ``bare``    — ``nvim``
2. ``file``    — ``nvim <file>``
3. ``session`` — ``nvim -S <Session.vim>``

Each scenario has a cold phase (``<cache>/luac`` deleted before each sample) and
a warm phase (preceded by discarded warmup runs). The cold/warm split is only
meaningful when ``vim.loader.enable()`` is active (it populates ``<cache>/luac``
with Lua bytecode); if no ``luac`` cache is found the script says so and the
cold numbers should be read as equal to warm. On macOS, run ``sudo purge``
before the script for a fully cold OS page cache on the first sample.

Usage
-----
    ./neovim-benchmark.py
    ./neovim-benchmark.py --runs 50 --warmup 5
    ./neovim-benchmark.py --cold-runs 0         # warm only
    ./neovim-benchmark.py --scenario bare
    ./neovim-benchmark.py --json results.json
"""

from __future__ import annotations

import argparse
import os
import re
import shutil
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
DEFAULT_COLD_RUNS = 3
DEFAULT_TIMEOUT_SEC = 30.0
DEFAULT_SESSION_NAME = "Session.vim"

# Line format: "  164.276  000.008: --- NVIM STARTED ---"
_STARTED_RE = re.compile(r"^\s*([0-9]+\.[0-9]+).*--- NVIM STARTED ---")

# Markers used to extract stdpath('cache') pollution-proof (the user's config
# loads, so plain stdout can contain config chatter; we slice between markers).
_CACHE_RE = re.compile(r"__BENCHCACHE__(.*?)__ENDCACHE__", re.S)

_QUIT_ON_UIENTER_LUA = (
    "vim.api.nvim_create_autocmd('UIEnter',"
    "{callback=function() vim.cmd('qa!') end})"
)


@dataclass
class ScenarioResult:
    name: str
    description: str
    command: list[str]
    cold: bench.Stats | None
    warm: bench.Stats | None


def parse_startuptime_log(log_path: Path) -> float:
    last: float | None = None
    with log_path.open("r", encoding="utf-8", errors="replace") as fh:
        for line in fh:
            m = _STARTED_RE.match(line)
            if m:
                last = float(m.group(1))
    if last is None:
        raise RuntimeError(
            f"no '--- NVIM STARTED ---' line in {log_path}; "
            "nvim crashed or exited before startup completed"
        )
    return last


def run_once(nvim_bin: str, extra_args: list[str], cwd: Path | None,
             timeout: float) -> float:
    """Run nvim once under a PTY, return ms at '--- NVIM STARTED ---'."""
    fd, log_str = tempfile.mkstemp(prefix="nvim-startuptime-", suffix=".log")
    os.close(fd)
    log_path = Path(log_str)
    try:
        cmd = [
            nvim_bin,
            "--startuptime", str(log_path),
            "-c", "lua " + _QUIT_ON_UIENTER_LUA,
            *extra_args,
        ]
        run = bench.run_under_pty(cmd, cwd=cwd, timeout=timeout, capture_stdout=False)
        if run.timed_out:
            raise RuntimeError(
                f"nvim did not exit within {timeout}s "
                f"(UIEnter may not have fired); command: {' '.join(cmd)}"
            )
        if run.returncode != 0:
            err = run.stderr.decode("utf-8", errors="replace").strip()
            raise RuntimeError(
                f"nvim exited with code {run.returncode}: {err or '(no stderr)'}\n"
                f"command: {' '.join(cmd)}"
            )
        return parse_startuptime_log(log_path)
    finally:
        log_path.unlink(missing_ok=True)


def get_nvim_cache_dir(nvim_bin: str) -> Path:
    """Ask Neovim for stdpath('cache'), config-aware and pollution-proof.

    We do NOT use --clean (the real config may set $NVIM_APPNAME, changing the
    cache path), so the user's config loads and can print to stdout. To stay
    robust we wrap the path in markers and slice it out, instead of trusting the
    whole captured stdout.
    """
    proc = subprocess.run(
        [nvim_bin, "--headless",
         "-c", "lua io.write('__BENCHCACHE__'..vim.fn.stdpath('cache')..'__ENDCACHE__')",
         "+q"],
        stdout=subprocess.PIPE, stderr=subprocess.PIPE, check=False,
    )
    out = proc.stdout.decode("utf-8", errors="replace")
    m = _CACHE_RE.search(out)
    if not m:
        err = proc.stderr.decode("utf-8", errors="replace").strip()
        raise RuntimeError(
            f"could not determine nvim cache dir; stderr: {err or '(none)'}"
        )
    return Path(m.group(1).strip())


def clear_lua_bytecode_cache(cache_dir: Path) -> None:
    shutil.rmtree(cache_dir / "luac", ignore_errors=True)


def luac_cache_active(cache_dir: Path | None) -> bool:
    """True if a populated <cache>/luac exists (i.e. vim.loader is enabled).

    Checked after runs: if the loader is on, a cold run repopulates luac; if it
    stays empty/absent, the cold/warm split is not meaningful.
    """
    if cache_dir is None:
        return False
    luac = cache_dir / "luac"
    try:
        return luac.is_dir() and any(luac.iterdir())
    except OSError:
        return False


def bench_scenario(
    name: str,
    description: str,
    nvim_args: list[str],
    nvim_bin: str,
    cold_runs: int,
    warmup: int,
    runs: int,
    cache_dir: Path | None,
    cwd: Path | None,
    timeout: float,
    verbose: bool,
    quiet: bool,
    pal: bench.Palette,
) -> ScenarioResult:
    full_cmd = [nvim_bin, *nvim_args]
    if not quiet:
        print(
            f"\n{bench.header(name, description, pal)}\n"
            f"  command: {' '.join(full_cmd)}\n"
            f"  cold: {cold_runs}, warmup: {warmup}, warm: {runs}",
            flush=True,
        )

    def phase(count: int, label: str, clear_each: Path | None) -> list[float]:
        samples: list[float] = []
        if not quiet:
            print(f"  {label} phase ", end="", flush=True)
        t0 = time.perf_counter()
        for i in range(count):
            if clear_each is not None:
                clear_lua_bytecode_cache(clear_each)
            t = run_once(nvim_bin, nvim_args, cwd=cwd, timeout=timeout)
            samples.append(t)
            if verbose:
                print(f"\n    {label} {i + 1:>2}: {t:7.2f} ms", end="", flush=True)
            elif not quiet:
                print(".", end="", flush=True)
        if not quiet:
            print(f"  ({time.perf_counter() - t0:.1f}s)", flush=True)
        return samples

    cold_samples: list[float] = []
    if cold_runs > 0:
        cold_samples = phase(cold_runs, "cold", clear_each=cache_dir)

    warm_samples: list[float] = []
    if runs > 0:
        for i in range(warmup):
            t = run_once(nvim_bin, nvim_args, cwd=cwd, timeout=timeout)
            if verbose:
                print(f"    warmup {i + 1:>2}: {t:7.2f} ms", flush=True)
        warm_samples = phase(runs, "warm", clear_each=None)

    return ScenarioResult(
        name=name,
        description=description,
        command=full_cmd,
        cold=bench.summarize(cold_samples),
        warm=bench.summarize(warm_samples),
    )


def format_table(results: list[ScenarioResult], pal: bench.Palette, *,
                 loader_active: bool, did_cold: bool, cleared_cache: bool) -> str:
    rows: list[list[str]] = []
    notes: list[str] = []
    for r in results:
        for state, s in (("cold", r.cold), ("warm", r.warm)):
            if s is None:
                continue
            rows.append([r.name, state, *bench.stat_cells(s)])
            note = bench.outlier_note(s, label=f"{r.name}/{state}")
            if note:
                notes.append(pal.yellow(f"⚠ {note}"))
    if not rows:
        return "(no samples collected)"

    headers = ["scenario", "state", *bench.STAT_HEADERS]
    aligns = ["l", "l", *bench.STAT_ALIGNS]
    lines = [bench.render_table(headers, rows, aligns=aligns,
                                highlight="median", pal=pal)]
    lines += notes

    # Only blame vim.loader when we actually cleared a known cache dir and it
    # stayed empty — not when caching was skipped or the cache dir was unknown.
    if did_cold and cleared_cache and not loader_active:
        lines.append(pal.yellow(
            "⚠ no populated <cache>/luac found — vim.loader is not enabled, so "
            "cold ≈ warm (the cold/warm split is not meaningful here)."
        ))

    lines += [
        "",
        "All times in ms, cumulative at '--- NVIM STARTED ---' (measured from",
        "exec()), captured under a PTY so UIEnter fires (small overhead vs a real",
        "terminal; for an absolute number run 'nvim --startuptime' in your terminal).",
        "cold = <cache>/luac deleted before each sample (cold Lua bytecode); the",
        "       OS page cache is only truly cold for the first sample overall —",
        "       run 'sudo purge' beforehand for a fully cold first run.",
        "warm = preceded by warmup runs; steady-state.",
        "Per-plugin attribution: ':Lazy profile' or rhysd/vim-startuptime.",
    ]
    return "\n".join(lines)


def parse_args() -> argparse.Namespace:
    p = argparse.ArgumentParser(
        description="Benchmark Neovim startup time.",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog=(
            "Examples:\n"
            "  %(prog)s\n"
            "  %(prog)s --runs 50 --warmup 5\n"
            "  %(prog)s --cold-runs 5 --runs 30\n"
            "  %(prog)s --scenario session --session ~/proj/Session.vim\n"
            "  %(prog)s --json results.json --verbose\n"
        ),
    )
    p.add_argument("-r", "--runs", type=int, default=DEFAULT_RUNS,
                   help=f"warm iterations per scenario (default: {DEFAULT_RUNS}, 0 to skip)")
    p.add_argument("-w", "--warmup", type=int, default=DEFAULT_WARMUP,
                   help=f"warmup iterations before warm phase (default: {DEFAULT_WARMUP})")
    p.add_argument("-c", "--cold-runs", type=int, default=DEFAULT_COLD_RUNS,
                   help=f"cold iterations per scenario (default: {DEFAULT_COLD_RUNS}, 0 to skip)")
    p.add_argument("--no-clear-cache", action="store_true",
                   help="do not delete <cache>/luac between cold runs")
    p.add_argument("-s", "--scenario", choices=["bare", "file", "session", "all"],
                   default="all", help="which scenario to run (default: all)")
    p.add_argument("--nvim", default=os.environ.get("NVIM_BIN", "nvim"),
                   help="path to nvim binary (default: nvim, or $NVIM_BIN)")
    p.add_argument("--file", type=Path, default=None,
                   help="file to open for the 'file' scenario (default: this script)")
    p.add_argument("--session", type=Path, default=None,
                   help=f"Session.vim for 'session' scenario (default: {DEFAULT_SESSION_NAME} in CWD)")
    p.add_argument("--cwd", type=Path, default=None,
                   help="working directory to run nvim from")
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


def build_scenarios(args: argparse.Namespace) -> list[tuple[str, str, list[str]]]:
    file_arg = args.file if args.file else Path(__file__).resolve()
    cwd = args.cwd or Path.cwd()
    session = args.session if args.session else cwd / DEFAULT_SESSION_NAME
    scenarios: list[tuple[str, str, list[str]]] = []

    if args.scenario in ("bare", "all"):
        scenarios.append(("bare", "nvim with no arguments", []))

    if args.scenario in ("file", "all"):
        if not file_arg.exists():
            sys.exit(f"error: file does not exist: {file_arg}")
        scenarios.append(("file", f"nvim {file_arg.name}", [str(file_arg)]))

    if args.scenario in ("session", "all"):
        if session.exists():
            scenarios.append(
                ("session", f"nvim -S {session.name}", ["-S", str(session)])
            )
        elif args.scenario == "session":
            sys.exit(f"error: Session.vim not found: {session}")
        else:
            bench.warn(f"skipping 'session': {session} not found")

    return scenarios


def main() -> int:
    args = parse_args()
    for name in ("runs", "warmup", "cold_runs"):
        if getattr(args, name) < 0:
            sys.exit(f"error: --{name.replace('_', '-')} must be >= 0")
    if args.cold_runs == 0 and args.runs == 0:
        sys.exit("error: --cold-runs and --runs are both 0; nothing to measure")

    pal = bench.make_palette(args)

    try:
        version_line = bench.tool_version([args.nvim, "--version"])
    except RuntimeError as e:
        sys.exit(f"error: {e}")
    print(f"Neovim: {version_line}")
    print(f"Python: {sys.version.split()[0]}")
    print(f"CWD:    {args.cwd or Path.cwd()}")

    cache_dir: Path | None = None
    if not args.no_clear_cache and args.cold_runs > 0:
        try:
            cache_dir = get_nvim_cache_dir(args.nvim)
        except RuntimeError as e:
            bench.warn(f"{e}; cold runs will not clear any cache")
        else:
            print(f"Cache:  {cache_dir} (will delete <cache>/luac before each cold run)")

    scenarios = build_scenarios(args)
    if not scenarios:
        sys.exit("error: no scenarios to run")

    results = [
        bench_scenario(
            name=name,
            description=desc,
            nvim_args=nvim_args,
            nvim_bin=args.nvim,
            cold_runs=args.cold_runs,
            warmup=args.warmup,
            runs=args.runs,
            cache_dir=cache_dir,
            cwd=args.cwd,
            timeout=args.timeout,
            verbose=args.verbose,
            quiet=args.quiet,
            pal=pal,
        )
        for name, desc, nvim_args in scenarios
    ]

    did_cold = args.cold_runs > 0
    loader_active = luac_cache_active(cache_dir)
    print("\n" + format_table(results, pal, loader_active=loader_active,
                              did_cold=did_cold, cleared_cache=cache_dir is not None))

    legend_extra = [
        ("startup ms", "cumulative time at '--- NVIM STARTED ---', measured from exec()"),
    ]
    if did_cold:
        legend_extra += [
            ("cold", "<cache>/luac cleared before each run — cold Lua bytecode"),
            ("warm", "steady-state; caches warm"),
        ]
    print("\n" + bench.legend(legend_extra, pal=pal))

    if args.json:
        payload = {
            "nvim_version": version_line,
            "cold_runs": args.cold_runs,
            "warmup": args.warmup,
            "runs": args.runs,
            "cleared_lua_cache": cache_dir is not None,
            "vim_loader_active": loader_active if did_cold else None,
            "results": [
                {
                    "name": r.name,
                    "description": r.description,
                    "command": r.command,
                    "cold": r.cold.to_dict() if r.cold else None,
                    "warm": r.warm.to_dict() if r.warm else None,
                }
                for r in results
            ],
        }
        bench.write_json(args.json, payload)
        print(f"\nJSON written to {args.json}")

    return 0


if __name__ == "__main__":
    try:
        sys.exit(main())
    except KeyboardInterrupt:
        sys.exit(130)
    except RuntimeError as e:
        sys.exit(f"error: {e}")
