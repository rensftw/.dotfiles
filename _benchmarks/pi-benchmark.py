#!/usr/bin/env python3
"""Benchmark Pi agent interactive startup.

This script runs `pi` in its built-in startup benchmark mode, multiple times,
then reports aggregate statistics for both wall-clock process time and Pi's
internal startup timing breakdown.

Examples:
  ./pi-benchmark.py
  ./pi-benchmark.py --runs 50 --warmup 5
  ./pi-benchmark.py --clean --runs 30
  ./pi-benchmark.py --compare-clean --runs 20
  ./pi-benchmark.py --compile-cache --runs 20
  ./pi-benchmark.py --cmd "node /path/to/pi/dist/cli.js" -- --no-extensions
"""

from __future__ import annotations

import argparse
import dataclasses
import json
import math
import os
import platform
import re
import shlex
import shutil
import statistics
import subprocess
import sys
import time
from collections import defaultdict
from pathlib import Path
from typing import Any

sys.path.insert(0, str(Path(__file__).resolve().parent))
import _bench_common as bench  # noqa: E402


DEFAULT_RUNS = 20
DEFAULT_WARMUP = 3
DEFAULT_COLD_RUNS = 1
DEFAULT_TIMEOUT_SECONDS = 30.0
DEFAULT_SLEEP_BETWEEN_SECONDS = 0.2
DEFAULT_COMPILE_CACHE_RUNS = 10

CLEAN_PI_FLAGS = [
    "--no-context-files",
    "--no-extensions",
    "--no-skills",
    "--no-prompt-templates",
    "--no-themes",
]
RESOURCE_COUNT_MARKER = "__PI_BENCHMARK_RESOURCE_COUNTS__"

TIMING_RE = re.compile(r"^\s*(?P<label>[^:]+):\s*(?P<ms>\d+(?:\.\d+)?)ms\s*$")
URI_SCHEME_RE = re.compile(r"^[A-Za-z][A-Za-z0-9+.-]*:")

# Palette for colored output; replaced from CLI args in main().
PAL = bench.Palette(False)


@dataclasses.dataclass
class RunResult:
    scenario: str
    index: int
    phase: str
    warmup: bool
    command: list[str]
    returncode: int | None
    timed_out: bool
    wall_ms: float
    timings_ms: dict[str, float]
    stdout: str
    stderr: str
    error: str | None = None

    @property
    def ok(self) -> bool:
        return self.returncode == 0 and not self.timed_out

    @property
    def internal_total_ms(self) -> float | None:
        return self.timings_ms.get("TOTAL")


@dataclasses.dataclass(frozen=True)
class Scenario:
    name: str
    clean: bool


def parse_args(argv: list[str]) -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Benchmark Pi agent startup performance.",
        formatter_class=argparse.ArgumentDefaultsHelpFormatter,
        epilog=(
            "Extra Pi arguments must come after '--'. Example: "
            "./pi-benchmark.py --runs 30 -- --no-extensions --no-context-files"
        ),
    )
    parser.add_argument("-r", "-n", "--runs", type=bench.pos_int, default=DEFAULT_RUNS,
                        help="Number of measured runs.")
    parser.add_argument("--cold-runs", type=bench.nonneg_int, default=DEFAULT_COLD_RUNS,
                        help=(
                            "Measured runs to classify as cold-start / first-run. "
                            "Best-effort only: the script does not purge OS file caches."
                        ))
    parser.add_argument("-w", "--warmup", type=bench.nonneg_int, default=DEFAULT_WARMUP,
                        help=(
                            "Unmeasured warmup runs executed after cold runs and before warm measured runs. "
                            "Use --cold-runs 0 for the classic 'warmup before all measurements' style."
                        ))
    parser.add_argument("--cmd", default=os.environ.get("PI_BENCHMARK_CMD", "pi"),
                        help="Pi command to execute. May include arguments; shell quoting is honored.")
    parser.add_argument("--cwd", type=Path, default=Path.cwd(),
                        help="Working directory for Pi runs.")
    parser.add_argument("--timeout", type=bench.pos_float, default=DEFAULT_TIMEOUT_SECONDS,
                        help="Per-run timeout in seconds.")
    parser.add_argument("--sleep-between", type=bench.nonneg_float,
                        default=DEFAULT_SLEEP_BETWEEN_SECONDS,
                        help="Seconds to sleep between runs.")
    parser.add_argument("--allow-network", action="store_true",
                        help="Do not force PI_OFFLINE=1. By default startup network checks are disabled for stability.")
    parser.add_argument("--save-session", action="store_true",
                        help="Do not add --no-session. By default session writes are disabled for benchmark isolation.")
    parser.add_argument("--clean", action="store_true",
                        help="Disable resource/context discovery: extensions, skills, prompt templates, themes, context files.")
    parser.add_argument("--compare-clean", action="store_true",
                        help="Run and compare both full-config startup and --clean startup.")
    parser.add_argument("--no-resource-counts", action="store_true",
                        help="Skip SDK-based resource counting after benchmark runs.")
    parser.add_argument("--env", action="append", default=[], metavar="KEY=VALUE",
                        help="Additional environment override. Can be repeated.")
    parser.add_argument("--json", "--json-out", dest="json_out", metavar="PATH",
                        help="Write raw runs and computed stats as JSON.")
    parser.add_argument("--csv", "--csv-out", dest="csv_out", metavar="PATH",
                        help="Write one CSV row per measured run, including stage columns.")
    parser.add_argument("--raw-dir", metavar="DIR",
                        help="Write raw stdout/stderr for each run to this directory.")
    parser.add_argument("--top-stages", type=bench.nonneg_int, default=15,
                        help="Number of internal timing stages to show, sorted by mean time. 0 shows all.")
    parser.add_argument("--fail-fast", action="store_true",
                        help="Stop after the first failed or timed-out run.")
    parser.add_argument("--quiet", action="store_true",
                        help="Suppress per-run progress messages on stderr.")
    parser.add_argument("--compile-cache", action="store_true",
                        help="Also measure NODE_COMPILE_CACHE cold vs warm (V8 bytecode "
                             "cache; needs Node >= 22.1).")
    parser.add_argument("--compile-cache-runs", type=bench.pos_int,
                        default=DEFAULT_COMPILE_CACHE_RUNS, metavar="N",
                        help=f"runs per cache phase for --compile-cache "
                             f"(default: {DEFAULT_COMPILE_CACHE_RUNS}).")
    bench.add_color_args(parser)
    parser.add_argument("pi_args", nargs=argparse.REMAINDER,
                        help="Extra arguments passed to Pi after '--'.")
    args = parser.parse_args(argv)
    if args.pi_args and args.pi_args[0] == "--":
        args.pi_args = args.pi_args[1:]
    return args


def parse_env_assignment(assignment: str) -> tuple[str, str]:
    if "=" not in assignment:
        raise ValueError(f"Invalid --env value {assignment!r}; expected KEY=VALUE")
    key, value = assignment.split("=", 1)
    if not key:
        raise ValueError(f"Invalid --env value {assignment!r}; key is empty")
    return key, value


def scenario_list(args: argparse.Namespace) -> list[Scenario]:
    if args.compare_clean:
        return [Scenario("full", False), Scenario("clean", True)]
    return [Scenario("clean" if args.clean else "full", args.clean)]


def build_command(args: argparse.Namespace, *, clean: bool | None = None) -> list[str]:
    command = shlex.split(args.cmd)
    if not command:
        raise ValueError("--cmd parsed to an empty command")

    scenario_clean = args.clean if clean is None else clean
    pi_args: list[str] = []
    if not args.save_session:
        pi_args.append("--no-session")
    if scenario_clean:
        pi_args.extend(CLEAN_PI_FLAGS)
    pi_args.extend(args.pi_args)
    return command + pi_args


def build_env(args: argparse.Namespace) -> dict[str, str]:
    env = os.environ.copy()
    env["PI_STARTUP_BENCHMARK"] = "1"
    env["PI_TIMING"] = "1"
    env.setdefault("TERM", "xterm-256color")
    env.setdefault("COLUMNS", "120")
    env.setdefault("LINES", "40")

    if not args.allow_network:
        env["PI_OFFLINE"] = "1"
        env["PI_SKIP_VERSION_CHECK"] = "1"
        env.setdefault("PI_TELEMETRY", "0")

    for assignment in args.env:
        key, value = parse_env_assignment(assignment)
        env[key] = value
    return env


def run_once(scenario: str, index: int, phase: str, command: list[str], env: dict[str, str], cwd: str,
             timeout: float) -> RunResult:
    rows = int(env.get("LINES", "40") or "40")
    cols = int(env.get("COLUMNS", "120") or "120")
    error: str | None = None
    timed_out = False
    returncode: int | None = None
    stdout = ""
    stderr = ""

    # The shared PTY runner kills the whole process group on timeout AND on
    # KeyboardInterrupt (re-raised), so Ctrl-C never orphans a pi child.
    start_ns = time.perf_counter_ns()
    try:
        run = bench.run_under_pty(
            command, cwd=cwd, env=env, timeout=timeout,
            capture_stdout=True, set_winsize=(rows, cols),
        )
        returncode = run.returncode
        timed_out = run.timed_out
        stdout = run.stdout.decode("utf-8", "replace")
        stderr = run.stderr.decode("utf-8", "replace")
        if timed_out:
            error = f"timed out after {timeout:.1f}s"
    except FileNotFoundError as exc:
        error = str(exc)
    except Exception as exc:
        error = f"{type(exc).__name__}: {exc}"
    wall_ms = (time.perf_counter_ns() - start_ns) / 1_000_000.0

    timings = parse_timings(stderr)
    if not timings:
        # Self-healing: pi writes PI_TIMING to stderr today; fall back to stdout
        # so a future build that switches streams doesn't silently zero out the
        # internal-timing breakdown.
        timings = parse_timings(stdout)
    if error is None and returncode not in (0, None):
        error = f"exit code {returncode}"

    return RunResult(
        scenario=scenario,
        index=index,
        phase=phase,
        warmup=phase == "warmup",
        command=command,
        returncode=returncode,
        timed_out=timed_out,
        wall_ms=wall_ms,
        timings_ms=timings,
        stdout=stdout,
        stderr=stderr,
        error=error,
    )


def parse_timings(stderr: str) -> dict[str, float]:
    timings: dict[str, float] = {}
    for line in bench.strip_ansi(stderr).splitlines():
        match = TIMING_RE.match(line)
        if not match:
            continue
        timings[match.group("label").strip()] = float(match.group("ms"))
    return timings


def summarize(values: list[float]) -> dict[str, float | int]:
    if not values:
        return {"n": 0}
    # Sort once and reuse, rather than re-sorting inside percentile 5x.
    ordered = sorted(values)
    n = len(ordered)
    mean = statistics.fmean(ordered)
    sample_sigma = statistics.stdev(ordered) if n > 1 else 0.0
    p25 = bench.percentile(ordered, 25)
    p75 = bench.percentile(ordered, 75)
    return {
        "n": n,
        "mean": mean,
        "median": statistics.median(ordered),
        "p75": p75,
        "p90": bench.percentile(ordered, 90),
        "p95": bench.percentile(ordered, 95),
        "p99": bench.percentile(ordered, 99),
        "stdev": sample_sigma,
        "min": ordered[0],
        "max": ordered[-1],
        "range": ordered[-1] - ordered[0],
        "iqr": p75 - p25,
        "cv_pct": (sample_sigma / mean * 100.0) if mean else 0.0,
    }


def format_ms(value: float | int | None) -> str:
    if value is None:
        return "n/a"
    if isinstance(value, float) and math.isnan(value):
        return "n/a"
    return f"{float(value):,.1f}"


def format_signed_ms(value: float | int | None) -> str:
    if value is None:
        return "n/a"
    if isinstance(value, float) and math.isnan(value):
        return "n/a"
    return f"{float(value):+,.1f}"


def format_ms_cell(value: float | int | None, *, signed: bool = False) -> str:
    formatter = format_signed_ms if signed else format_ms
    formatted = formatter(value)
    return formatted if formatted == "n/a" else f"{formatted}ms"


def format_pct(value: float | int | None) -> str:
    if value is None:
        return "n/a"
    if isinstance(value, float) and math.isnan(value):
        return "n/a"
    return f"{float(value):,.1f}%"


def format_signed_pct(value: float | int | None) -> str:
    if value is None:
        return "n/a"
    if isinstance(value, float) and math.isnan(value):
        return "n/a"
    return f"{float(value):+,.1f}%"


def stats_line(name: str, stats: dict[str, float | int]) -> str:
    if not stats or stats.get("n", 0) == 0:
        return f"{name}: no data"
    return (
        f"{name}: n={stats['n']}  "
        f"mean={format_ms(stats['mean'])}ms  "
        f"median={format_ms(stats['median'])}ms  "
        f"p90={format_ms(stats['p90'])}ms  "
        f"p95={format_ms(stats['p95'])}ms  "
        f"p99={format_ms(stats['p99'])}ms  "
        f"σ={format_ms(stats['stdev'])}ms  "
        f"IQR={format_ms(stats['iqr'])}ms  "
        f"min={format_ms(stats['min'])}ms  "
        f"max={format_ms(stats['max'])}ms  "
        f"CV={format_pct(stats['cv_pct'])}"
    )


def compute_stage_stats(measured: list[RunResult]) -> dict[str, dict[str, float | int]]:
    by_label: dict[str, list[float]] = defaultdict(list)
    for result in measured:
        if not result.ok:
            continue
        for label, ms in result.timings_ms.items():
            if label == "TOTAL":
                continue
            by_label[label].append(ms)
    return {label: summarize(values) for label, values in by_label.items()}


def compute_phase_stats(measured: list[RunResult]) -> dict[str, dict[str, dict[str, float | int]]]:
    phases: dict[str, dict[str, dict[str, float | int]]] = {}
    for phase in ("cold", "warm"):
        ok_phase = [r for r in measured if r.phase == phase and r.ok]
        wall_values = [r.wall_ms for r in ok_phase]
        internal_values = [r.internal_total_ms for r in ok_phase if r.internal_total_ms is not None]
        phases[phase] = {
            "wall_ms": summarize(wall_values),
            "pi_internal_total_ms": summarize([v for v in internal_values if v is not None]),
        }
    return phases


def collect_report(args: argparse.Namespace, scenario: Scenario, command: list[str], env: dict[str, str],
                   all_results: list[RunResult], resource_counts: dict[str, Any] | None) -> dict[str, Any]:
    measured = [r for r in all_results if not r.warmup]
    ok_measured = [r for r in measured if r.ok]
    failures = [r for r in measured if not r.ok]
    wall_values = [r.wall_ms for r in ok_measured]
    internal_values = [r.internal_total_ms for r in ok_measured if r.internal_total_ms is not None]
    cold_runs = min(args.cold_runs, args.runs)

    return {
        "scenario": {"name": scenario.name, "clean": scenario.clean},
        "command": command,
        "cwd": str(Path(args.cwd).resolve()),
        "runs_requested": args.runs,
        "cold_runs_requested": cold_runs,
        "warm_runs_requested": args.runs - cold_runs,
        "warmup_requested": args.warmup,
        "measured_successes": len(ok_measured),
        "measured_failures": len(failures),
        "environment_overrides": env_overrides_for_report(args, env),
        "system": system_info(shlex.split(args.cmd), env, args.cwd),
        "resource_counts": resource_counts,
        "stats": {
            "wall_ms": summarize(wall_values),
            "pi_internal_total_ms": summarize([v for v in internal_values if v is not None]),
            "phases": compute_phase_stats(measured),
            "stages_ms": compute_stage_stats(measured),
        },
        "runs": [run_to_jsonable(r, include_raw=False) for r in measured],
        "warmups": [run_to_jsonable(r, include_raw=False) for r in all_results if r.warmup],
    }


def env_overrides_for_report(args: argparse.Namespace, env: dict[str, str]) -> dict[str, str]:
    keys = ["PI_STARTUP_BENCHMARK", "PI_TIMING", "PI_OFFLINE", "PI_SKIP_VERSION_CHECK", "PI_TELEMETRY",
            "TERM", "COLUMNS", "LINES"]
    for assignment in args.env:
        key, _ = parse_env_assignment(assignment)
        if key not in keys:
            keys.append(key)
    return {key: env[key] for key in keys if key in env}


def system_info(base_command: list[str], env: dict[str, str], cwd: str | Path) -> dict[str, Any]:
    info: dict[str, Any] = {
        "platform": platform.platform(),
        "machine": platform.machine(),
        "processor": platform.processor(),
        "python": platform.python_version(),
        "cpu_count": os.cpu_count(),
    }
    version_cmd = base_command + ["--version"]
    try:
        completed = subprocess.run(
            version_cmd,
            cwd=cwd,
            env=env,
            stdin=subprocess.DEVNULL,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
            timeout=5,
            check=False,
        )
        version_lines = (completed.stdout or completed.stderr).strip().splitlines()
        version = version_lines[0] if version_lines else ""
        if version:
            info["pi_version"] = version
    except Exception as exc:
        info["pi_version_error"] = str(exc)

    try:
        completed = subprocess.run(
            ["node", "--version"],
            stdin=subprocess.DEVNULL,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
            timeout=5,
            check=False,
        )
        node_version = completed.stdout.strip() or completed.stderr.strip()
        if node_version:
            info["node"] = node_version.splitlines()[0]
    except Exception:
        pass
    return info


NODE_RESOURCE_COUNTS_SCRIPT = r"""
const [indexPath, configJson] = process.argv.slice(1);
const marker = "__PI_BENCHMARK_RESOURCE_COUNTS__";

try {
  const { pathToFileURL } = await import("node:url");
  const pi = await import(pathToFileURL(indexPath).href);
  const { createAgentSessionServices, createAgentSessionFromServices, SessionManager } = pi;
  const config = JSON.parse(configJson);
  const extensionRuntimeErrors = [];

  const services = await createAgentSessionServices({
    cwd: config.cwd,
    resourceLoaderOptions: config.resourceLoaderOptions,
  });
  const { session } = await createAgentSessionFromServices({
    services,
    sessionManager: SessionManager.inMemory(config.cwd),
    noTools: "all",
    sessionStartEvent: { type: "session_start", reason: "startup" },
  });

  try {
    await session.bindExtensions({
      onError: (event) => extensionRuntimeErrors.push(event),
      shutdownHandler: () => {},
    });
  } catch (err) {
    extensionRuntimeErrors.push({
      extensionPath: "<bindExtensions>",
      event: "bindExtensions",
      error: err && err.message ? err.message : String(err),
      stack: err && err.stack ? err.stack : undefined,
    });
  }

  const loader = services.resourceLoader;
  const extensions = loader.getExtensions();
  const skills = loader.getSkills();
  const prompts = loader.getPrompts();
  const themes = loader.getThemes();
  const agentsFiles = loader.getAgentsFiles();
  const customThemes = themes.themes.filter((theme) => theme && theme.sourcePath);

  const payload = {
    counts: {
      extensions: extensions.extensions.length,
      extension_errors: extensions.errors.length,
      extension_runtime_errors: extensionRuntimeErrors.length,
      skills: skills.skills.length,
      skill_diagnostics: skills.diagnostics.length,
      prompt_templates: prompts.prompts.length,
      prompt_diagnostics: prompts.diagnostics.length,
      themes: themes.themes.length,
      custom_themes: customThemes.length,
      theme_diagnostics: themes.diagnostics.length,
      context_files: agentsFiles.agentsFiles.length,
    },
    details: {
      extensions: extensions.extensions.map((extension) => extension.path),
      extension_errors: extensions.errors,
      extension_runtime_errors: extensionRuntimeErrors,
      skills: skills.skills.map((skill) => ({ name: skill.name, path: skill.filePath })),
      skill_diagnostics: skills.diagnostics,
      prompt_templates: prompts.prompts.map((prompt) => ({ name: prompt.name, path: prompt.filePath })),
      prompt_diagnostics: prompts.diagnostics,
      themes: themes.themes.map((theme) => ({ name: theme.name, path: theme.sourcePath || null })),
      theme_diagnostics: themes.diagnostics,
      context_files: agentsFiles.agentsFiles.map((file) => file.path),
    },
  };

  console.log(marker + JSON.stringify(payload));
  session.dispose();
} catch (err) {
  console.error(err && err.stack ? err.stack : String(err));
  process.exit(1);
}
"""


def resolve_pi_package_index(base_command: list[str], cwd: str) -> str | None:
    if not base_command:
        return None

    executable = base_command[0]
    script_candidate: str | None = None
    executable_name = Path(executable).name
    if executable_name in {"node", "nodejs", "bun"} and len(base_command) > 1:
        script_candidate = base_command[1]
    else:
        script_candidate = shutil.which(executable) or executable

    script_path = Path(script_candidate).expanduser()
    if not script_path.is_absolute():
        cwd_candidate = Path(cwd) / script_path
        if cwd_candidate.exists():
            script_path = cwd_candidate
    if not script_path.exists():
        return None

    try:
        script_path = script_path.resolve()
    except OSError:
        script_path = Path(os.path.realpath(str(script_path)))

    candidates = [script_path if script_path.is_dir() else script_path.parent, *script_path.parents]
    for parent in candidates:
        package_json = parent / "package.json"
        if not package_json.exists():
            continue
        try:
            package_data = json.loads(package_json.read_text(encoding="utf-8"))
        except Exception:
            continue
        if package_data.get("name") != "@earendil-works/pi-coding-agent":
            continue
        index_js = parent / "dist" / "index.js"
        if index_js.exists():
            return str(index_js)
    return None


def is_local_resource_path(value: str) -> bool:
    if value.startswith(("/", "./", "../", "~")):
        return True
    if URI_SCHEME_RE.match(value):
        return False
    return "/" in value or (os.altsep is not None and os.altsep in value)


def resolve_resource_path_arg(value: str, cwd: str) -> str:
    if not is_local_resource_path(value):
        return value
    expanded = Path(value).expanduser()
    if expanded.is_absolute():
        return str(expanded.resolve())
    return str((Path(cwd) / expanded).resolve())


def parse_resource_relevant_pi_args(pi_args: list[str], cwd: str, scenario_clean: bool) -> dict[str, Any]:
    options: dict[str, Any] = {
        "noExtensions": scenario_clean,
        "noSkills": scenario_clean,
        "noPromptTemplates": scenario_clean,
        "noThemes": scenario_clean,
        "noContextFiles": scenario_clean,
        "additionalExtensionPaths": [],
        "additionalSkillPaths": [],
        "additionalPromptTemplatePaths": [],
        "additionalThemePaths": [],
    }

    def add_path(key: str, raw_value: str | None) -> None:
        if raw_value:
            options[key].append(resolve_resource_path_arg(raw_value, cwd))

    i = 0
    while i < len(pi_args):
        token = pi_args[i]
        next_value = pi_args[i + 1] if i + 1 < len(pi_args) else None

        if token == "--no-extensions":
            options["noExtensions"] = True
        elif token == "--no-skills":
            options["noSkills"] = True
        elif token == "--no-prompt-templates":
            options["noPromptTemplates"] = True
        elif token == "--no-themes":
            options["noThemes"] = True
        elif token in {"--no-context-files", "-nc"}:
            options["noContextFiles"] = True
        elif token in {"--extension", "-e"}:
            add_path("additionalExtensionPaths", next_value)
            i += 1
        elif token.startswith("--extension="):
            add_path("additionalExtensionPaths", token.split("=", 1)[1])
        elif token == "--skill":
            add_path("additionalSkillPaths", next_value)
            i += 1
        elif token.startswith("--skill="):
            add_path("additionalSkillPaths", token.split("=", 1)[1])
        elif token == "--prompt-template":
            add_path("additionalPromptTemplatePaths", next_value)
            i += 1
        elif token.startswith("--prompt-template="):
            add_path("additionalPromptTemplatePaths", token.split("=", 1)[1])
        elif token == "--theme":
            add_path("additionalThemePaths", next_value)
            i += 1
        elif token.startswith("--theme="):
            add_path("additionalThemePaths", token.split("=", 1)[1])
        i += 1

    return options


def collect_resource_counts(args: argparse.Namespace, scenario: Scenario, env: dict[str, str], cwd: str) -> dict[str, Any] | None:
    if args.no_resource_counts:
        return None

    base_command = shlex.split(args.cmd)
    index_path = resolve_pi_package_index(base_command, cwd)
    if not index_path:
        return {"error": "Could not locate @earendil-works/pi-coding-agent dist/index.js from --cmd"}

    resource_options = parse_resource_relevant_pi_args(args.pi_args, cwd, scenario.clean)
    config = {
        "cwd": cwd,
        "resourceLoaderOptions": resource_options,
    }
    try:
        completed = subprocess.run(
            ["node", "--input-type=module", "-e", NODE_RESOURCE_COUNTS_SCRIPT, index_path, json.dumps(config)],
            cwd=cwd,
            env=env,
            stdin=subprocess.DEVNULL,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
            timeout=max(10.0, args.timeout),
            check=False,
        )
    except Exception as exc:
        return {"error": f"Resource count helper failed: {type(exc).__name__}: {exc}"}

    payload: dict[str, Any] | None = None
    for line in reversed(completed.stdout.splitlines()):
        if RESOURCE_COUNT_MARKER in line:
            raw = line.split(RESOURCE_COUNT_MARKER, 1)[1]
            try:
                payload = json.loads(raw)
            except json.JSONDecodeError as exc:
                return {"error": f"Resource count helper emitted invalid JSON: {exc}"}
            break

    if payload is None:
        message = "Resource count helper did not emit counts"
        if completed.returncode != 0:
            message += f" (exit code {completed.returncode})"
        stderr_tail = tail(completed.stderr)
        return {"error": message, "stderr_tail": stderr_tail}

    if completed.returncode != 0:
        payload["warning"] = f"Resource count helper exited with code {completed.returncode}"
        stderr_tail = tail(completed.stderr)
        if stderr_tail:
            payload["stderr_tail"] = stderr_tail
    return payload


def run_to_jsonable(result: RunResult, include_raw: bool) -> dict[str, Any]:
    data: dict[str, Any] = {
        "scenario": result.scenario,
        "index": result.index,
        "phase": result.phase,
        "warmup": result.warmup,
        "returncode": result.returncode,
        "timed_out": result.timed_out,
        "wall_ms": result.wall_ms,
        "pi_internal_total_ms": result.internal_total_ms,
        "timings_ms": result.timings_ms,
        "error": result.error,
    }
    if include_raw:
        data["stdout"] = result.stdout
        data["stderr"] = result.stderr
    return data


def render_resource_counts(resource_counts: dict[str, Any] | None) -> list[str]:
    if resource_counts is None:
        return ["Resource counts loaded at startup: skipped (--no-resource-counts)"]
    if "error" in resource_counts:
        lines = [f"Resource counts loaded at startup: unavailable ({resource_counts['error']})"]
        if resource_counts.get("stderr_tail"):
            lines.append(f"Resource helper stderr tail: {resource_counts['stderr_tail']}")
        return lines

    counts = resource_counts.get("counts", {})
    lines = [PAL.bold("Resource counts loaded at startup")]
    lines.append("-" * 33)
    lines.append(
        "extensions={extensions}  skills={skills}  prompt_templates={prompt_templates}  "
        "themes={themes} (custom={custom_themes})  context_files={context_files}".format(
            extensions=counts.get("extensions", "n/a"),
            skills=counts.get("skills", "n/a"),
            prompt_templates=counts.get("prompt_templates", "n/a"),
            themes=counts.get("themes", "n/a"),
            custom_themes=counts.get("custom_themes", "n/a"),
            context_files=counts.get("context_files", "n/a"),
        )
    )
    issue_parts = []
    for key, label in [
        ("extension_errors", "extension errors"),
        ("extension_runtime_errors", "extension runtime errors"),
        ("skill_diagnostics", "skill diagnostics"),
        ("prompt_diagnostics", "prompt diagnostics"),
        ("theme_diagnostics", "theme diagnostics"),
    ]:
        value = counts.get(key, 0)
        if value:
            issue_parts.append(f"{label}={value}")
    if issue_parts:
        lines.append("Resource issues: " + ", ".join(issue_parts))
    if resource_counts.get("warning"):
        lines.append(f"Warning: {resource_counts['warning']}")
    return lines


def render_total_timing_table(report: dict[str, Any]) -> list[str]:
    phases = report["stats"].get("phases", {})
    rows: list[tuple[str, str, dict[str, float | int]]] = [
        ("wall clock", "all", report["stats"].get("wall_ms", {"n": 0})),
        ("wall clock", "cold", phases.get("cold", {}).get("wall_ms", {"n": 0})),
        ("wall clock", "warm", phases.get("warm", {}).get("wall_ms", {"n": 0})),
        ("Pi internal TOTAL", "all", report["stats"].get("pi_internal_total_ms", {"n": 0})),
        ("Pi internal TOTAL", "cold", phases.get("cold", {}).get("pi_internal_total_ms", {"n": 0})),
        ("Pi internal TOTAL", "warm", phases.get("warm", {}).get("pi_internal_total_ms", {"n": 0})),
    ]

    headers = ["metric", "phase", "n", "median", "mean", "p90", "p95", "p99",
               "σ", "IQR", "min", "max", "CV"]
    aligns = ["l", "l"] + ["r"] * 11
    table_rows = []
    for metric, phase, stats in rows:
        table_rows.append([
            metric, phase, int(stats.get("n", 0)),
            format_ms(stats.get("median")), format_ms(stats.get("mean")),
            format_ms(stats.get("p90")), format_ms(stats.get("p95")),
            format_ms(stats.get("p99")), format_ms(stats.get("stdev")),
            format_ms(stats.get("iqr")), format_ms(stats.get("min")),
            format_ms(stats.get("max")), format_pct(stats.get("cv_pct")),
        ])
    table = bench.render_table(headers, table_rows, aligns=aligns,
                               highlight="median", pal=PAL, title="Total timing summary")
    return [table, ""]


def render_report(report: dict[str, Any], *, top_stages: int | None = None) -> str:
    lines: list[str] = []
    scenario = report.get("scenario", {})
    name = scenario.get("name") or "pi"
    command = " ".join(shlex.quote(part) for part in report["command"])
    lines.append(bench.header("pi startup benchmark", name, PAL))
    lines.append(f"Command: {command}")
    lines.append(f"CWD: {report['cwd']}")
    lines.append(
        f"Runs: {report['measured_successes']}/{report['runs_requested']} successful measured "
        f"(cold={report.get('cold_runs_requested', 0)}, warm={report.get('warm_runs_requested', 0)}, "
        f"+{report['warmup_requested']} warmup)"
    )
    if report["measured_failures"]:
        lines.append(f"Failures/timeouts: {report['measured_failures']}")

    sys_info = report["system"]
    version_bits = []
    if "pi_version" in sys_info:
        version_bits.append(f"pi {sys_info['pi_version']}")
    if "node" in sys_info:
        version_bits.append(f"node {sys_info['node']}")
    version_bits.append(f"python {sys_info['python']}")
    lines.append("Versions: " + ", ".join(version_bits))
    lines.append(f"System: {sys_info['platform']} ({sys_info.get('machine') or 'unknown arch'}), CPUs={sys_info.get('cpu_count')}")
    lines.append("Environment overrides: " + ", ".join(f"{k}={v}" for k, v in report["environment_overrides"].items()))
    lines.append("")

    lines.extend(render_resource_counts(report.get("resource_counts")))
    lines.append("")

    lines.extend(render_total_timing_table(report))

    missing_internal = [r for r in report["runs"] if r["returncode"] == 0 and r["pi_internal_total_ms"] is None]
    if missing_internal:
        lines.append(f"Warning: Pi internal TOTAL was missing for {len(missing_internal)} successful run(s).")
        lines.append("")

    stages = report["stats"]["stages_ms"]
    if stages:
        total_mean = report["stats"]["pi_internal_total_ms"].get("mean") or 0
        ranked = sorted(
            stages.items(),
            key=lambda item: float(item[1].get("mean", 0)),
            reverse=True,
        )
        if isinstance(top_stages, int) and top_stages > 0:
            ranked = ranked[:top_stages]
        headers = ["stage", "median", "mean", "p95", "σ", "min", "max", "%total"]
        aligns = ["l"] + ["r"] * 7
        stage_rows = []
        for label, stats in ranked:
            mean = float(stats.get("mean", math.nan))
            pct_total = (mean / float(total_mean) * 100.0) if total_mean else math.nan
            display_label = label if len(label) <= 42 else label[:41] + "…"
            stage_rows.append([
                display_label,
                format_ms(stats.get("median")), format_ms(stats.get("mean")),
                format_ms(stats.get("p95")), format_ms(stats.get("stdev")),
                format_ms(stats.get("min")), format_ms(stats.get("max")),
                format_pct(pct_total),
            ])
        lines.append(bench.render_table(
            headers, stage_rows, aligns=aligns, highlight="median", pal=PAL,
            title="Internal timing stages (sorted by mean ms)"))
        lines.append("")

    failures = [r for r in report["runs"] if r["returncode"] != 0 or r["timed_out"]]
    if failures:
        lines.append(PAL.bold("Failures"))
        lines.append("--------")
        for failure in failures[:5]:
            lines.append(
                f"run {failure['index']} ({failure.get('phase', 'unknown')}): returncode={failure['returncode']} "
                f"timed_out={failure['timed_out']} error={failure['error']}"
            )
        if len(failures) > 5:
            lines.append(f"... {len(failures) - 5} more failure(s)")
        lines.append("")

    lines.append(PAL.bold("Notes:"))
    lines.append("- Headline = median (robust on skewed startup); values in ms except n and CV.")
    lines.append("- Wall clock includes process launch, Node/module loading, Pi init, and benchmark-mode shutdown.")
    lines.append("- Pi internal TOTAL comes from PI_TIMING and starts after Pi's main module has entered main().")
    lines.append("- Cold-start is best-effort first-run separation; this script does not purge OS file caches.")
    lines.append("- Resource counts are collected after timing runs via Pi's SDK so counting does not warm the timed cold run.")
    lines.append("- σ is sample standard deviation; CV is σ / mean.")
    return "\n".join(lines)


def numeric_stat(report: dict[str, Any], metric: str, stat: str, phase: str | None = None) -> float | None:
    try:
        if phase:
            value = report["stats"]["phases"][phase][metric][stat]
        else:
            value = report["stats"][metric][stat]
    except KeyError:
        return None
    if not isinstance(value, (int, float)) or math.isnan(float(value)):
        return None
    return float(value)


def compare_values(full_value: float | None, clean_value: float | None) -> dict[str, float | None]:
    if full_value is None or clean_value is None:
        return {"full": full_value, "clean": clean_value, "delta": None, "delta_pct": None}
    delta = clean_value - full_value
    delta_pct = (delta / full_value * 100.0) if full_value else math.nan
    return {"full": full_value, "clean": clean_value, "delta": delta, "delta_pct": delta_pct}


def build_comparison(reports: list[dict[str, Any]]) -> dict[str, Any] | None:
    by_name = {report.get("scenario", {}).get("name"): report for report in reports}
    full = by_name.get("full")
    clean = by_name.get("clean")
    if not full or not clean:
        return None

    metric_specs = [
        ("wall_mean", "Wall mean", "wall_ms", "mean", None),
        ("wall_median", "Wall median", "wall_ms", "median", None),
        ("wall_p95", "Wall p95", "wall_ms", "p95", None),
        ("warm_wall_mean", "Warm wall mean", "wall_ms", "mean", "warm"),
        ("internal_mean", "Pi internal mean", "pi_internal_total_ms", "mean", None),
        ("internal_p95", "Pi internal p95", "pi_internal_total_ms", "p95", None),
        ("warm_internal_mean", "Warm internal mean", "pi_internal_total_ms", "mean", "warm"),
    ]
    metrics = {
        key: {
            "label": label,
            **compare_values(
                numeric_stat(full, metric, stat, phase),
                numeric_stat(clean, metric, stat, phase),
            ),
        }
        for key, label, metric, stat, phase in metric_specs
    }

    resources: dict[str, dict[str, int | None]] = {}
    full_counts = (full.get("resource_counts") or {}).get("counts") or {}
    clean_counts = (clean.get("resource_counts") or {}).get("counts") or {}
    for key in ["extensions", "skills", "prompt_templates", "themes", "custom_themes", "context_files"]:
        full_value = full_counts.get(key)
        clean_value = clean_counts.get(key)
        resources[key] = {
            "full": full_value if isinstance(full_value, int) else None,
            "clean": clean_value if isinstance(clean_value, int) else None,
            "delta": (clean_value - full_value) if isinstance(full_value, int) and isinstance(clean_value, int) else None,
        }

    return {"metrics": metrics, "resources": resources}


def render_comparison(comparison: dict[str, Any] | None) -> str:
    if comparison is None:
        return ""

    lines: list[str] = [
        PAL.bold("Full config vs --clean comparison"),
        "Timing deltas are clean - full; negative means --clean was faster.",
        "",
    ]
    metrics = comparison["metrics"]
    headers = ["metric", "full", "clean", "delta", "delta%"]
    aligns = ["l", "r", "r", "r", "r"]
    rows = [
        [
            m["label"],
            format_ms_cell(m.get("full")),
            format_ms_cell(m.get("clean")),
            format_ms_cell(m.get("delta"), signed=True),
            format_signed_pct(m.get("delta_pct")),
        ]
        for m in metrics.values()
    ]
    lines.append(bench.render_table(headers, rows, aligns=aligns, pal=PAL))

    resources = comparison.get("resources", {})
    if resources:
        lines.append("")
        lines.append("Resource count deltas are clean - full.")
        rheaders = ["resource", "full", "clean", "delta"]
        raligns = ["l", "r", "r", "r"]
        rrows = []
        for key, values in resources.items():
            fv = values.get("full")
            cv = values.get("clean")
            dv = values.get("delta")
            rrows.append([
                key,
                str(fv) if fv is not None else "n/a",
                str(cv) if cv is not None else "n/a",
                str(dv) if dv is not None else "n/a",
            ])
        lines.append(bench.render_table(rheaders, rrows, aligns=raligns, pal=PAL))
    lines.append("")
    lines.append("Comparison note: scenarios run sequentially; prefer warm-start rows "
                 "for stable full-vs-clean conclusions.")
    return "\n".join(lines)


def render_legend(*, measured_internal: bool = True) -> str:
    extra = [
        ("p90 / p99", "90th / 99th percentile — the deeper tail"),
        ("IQR", "interquartile range (p75 − p25) — outlier-robust spread"),
        ("wall clock", "process launch → benchmark-mode exit (what the user feels)"),
    ]
    if measured_internal:
        extra.append(("Pi internal TOTAL", "from PI_TIMING; starts when Pi's main() begins"))
    extra += [
        ("cold / warm", "best-effort first-run vs steady-state (no OS cache purge)"),
        ("%total", "a stage's mean as a share of Pi internal TOTAL"),
    ]
    return bench.legend(extra, pal=PAL)


def parse_node_version(cwd: str, env: dict[str, str]) -> tuple[int, int] | None:
    try:
        completed = subprocess.run(
            ["node", "--version"], cwd=cwd, env=env, stdin=subprocess.DEVNULL,
            stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True, timeout=5, check=False,
        )
    except Exception:
        return None
    m = re.search(r"v?(\d+)\.(\d+)", completed.stdout or completed.stderr or "")
    return (int(m.group(1)), int(m.group(2))) if m else None


def run_compile_cache_comparison(args: argparse.Namespace, cwd: str, count: int) -> dict[str, Any] | None:
    """Measure NODE_COMPILE_CACHE cold vs warm for the configured command.

    cold = cache dir cleared before each run (forces V8 to recompile); warm =
    cache primed once then reused. Needs Node >= 22.1 (the version that added
    the NODE_COMPILE_CACHE env var).
    """
    import tempfile

    env = build_env(args)
    version = parse_node_version(cwd, env)
    if version is None or version < (22, 1):
        found = "unknown" if version is None else f"v{version[0]}.{version[1]}"
        bench.warn(f"--compile-cache needs Node >= 22.1 (found {found}); skipping")
        return None

    command = build_command(args, clean=args.clean)
    cold_wall: list[float] = []
    warm_wall: list[float] = []
    cold_internal: list[float] = []
    warm_internal: list[float] = []

    progress(f"[compile-cache] NODE_COMPILE_CACHE cold vs warm, {count} runs each "
             f"(node {version[0]}.{version[1]})", args.quiet)
    with tempfile.TemporaryDirectory(prefix="pi-compile-cache-") as cache_dir:
        cenv = {**env, "NODE_COMPILE_CACHE": cache_dir}

        for i in range(count):
            shutil.rmtree(cache_dir, ignore_errors=True)
            os.makedirs(cache_dir, exist_ok=True)
            r = run_once("compile-cache", i + 1, "cold", command, cenv, cwd, args.timeout)
            if r.ok:
                cold_wall.append(r.wall_ms)
                if r.internal_total_ms is not None:
                    cold_internal.append(r.internal_total_ms)
            progress(f"[compile-cache] cold {i + 1}/{count}: wall={format_ms(r.wall_ms)}ms", args.quiet)

        run_once("compile-cache", 0, "warm", command, cenv, cwd, args.timeout)  # prime
        for i in range(count):
            r = run_once("compile-cache", i + 1, "warm", command, cenv, cwd, args.timeout)
            if r.ok:
                warm_wall.append(r.wall_ms)
                if r.internal_total_ms is not None:
                    warm_internal.append(r.internal_total_ms)
            progress(f"[compile-cache] warm {i + 1}/{count}: wall={format_ms(r.wall_ms)}ms", args.quiet)

    return {
        "node_version": f"v{version[0]}.{version[1]}",
        "runs": count,
        "wall_ms": {"cold": summarize(cold_wall), "warm": summarize(warm_wall)},
        "pi_internal_total_ms": {"cold": summarize(cold_internal), "warm": summarize(warm_internal)},
    }


def render_compile_cache(data: dict[str, Any] | None) -> str:
    if data is None:
        return ""
    lines = [
        PAL.bold("NODE_COMPILE_CACHE cold vs warm"),
        f"V8 bytecode cache (Node {data['node_version']}); cold = cache cleared each run, "
        "warm = cache primed. delta = warm − cold (negative means warm faster).",
        "",
    ]
    headers = ["metric", "n(cold)", "median(cold)", "n(warm)", "median(warm)", "delta", "delta%"]
    aligns = ["l"] + ["r"] * 6
    rows = []
    for label, key in (("wall clock", "wall_ms"), ("Pi internal TOTAL", "pi_internal_total_ms")):
        cold = data[key]["cold"] or {"n": 0}
        warm = data[key]["warm"] or {"n": 0}
        cmed = cold.get("median")
        wmed = warm.get("median")
        if isinstance(cmed, (int, float)) and isinstance(wmed, (int, float)):
            delta = wmed - cmed
            delta_pct = (delta / cmed * 100.0) if cmed else math.nan
            delta_cell = format_ms_cell(delta, signed=True)
            delta_pct_cell = format_signed_pct(delta_pct)
        else:
            delta_cell = "n/a"
            delta_pct_cell = "n/a"
        rows.append([
            label,
            int(cold.get("n", 0)), format_ms(cmed),
            int(warm.get("n", 0)), format_ms(wmed),
            delta_cell, delta_pct_cell,
        ])
    lines.append(bench.render_table(headers, rows, aligns=aligns, pal=PAL))
    return "\n".join(lines)


def write_csv(path: str, measured: list[RunResult]) -> None:
    import csv

    stage_labels = sorted({label for r in measured for label in r.timings_ms if label != "TOTAL"})
    fieldnames = [
        "scenario",
        "index",
        "phase",
        "returncode",
        "timed_out",
        "error",
        "wall_ms",
        "pi_internal_total_ms",
        *[f"stage:{label}" for label in stage_labels],
    ]
    with Path(path).open("w", newline="", encoding="utf-8") as fp:
        writer = csv.DictWriter(fp, fieldnames=fieldnames)
        writer.writeheader()
        for r in measured:
            row: dict[str, Any] = {
                "scenario": r.scenario,
                "index": r.index,
                "phase": r.phase,
                "returncode": r.returncode,
                "timed_out": r.timed_out,
                "error": r.error,
                "wall_ms": f"{r.wall_ms:.3f}",
                "pi_internal_total_ms": "" if r.internal_total_ms is None else f"{r.internal_total_ms:.3f}",
            }
            for label in stage_labels:
                value = r.timings_ms.get(label)
                row[f"stage:{label}"] = "" if value is None else f"{value:.3f}"
            writer.writerow(row)


def write_raw_outputs(raw_dir: str, result: RunResult) -> None:
    path = Path(raw_dir)
    path.mkdir(parents=True, exist_ok=True)
    prefix = "warmup" if result.warmup else result.phase
    base = f"{prefix}-{result.index:03d}"
    (path / f"{base}.stdout.txt").write_text(result.stdout, encoding="utf-8")
    (path / f"{base}.stderr.txt").write_text(result.stderr, encoding="utf-8")
    (path / f"{base}.json").write_text(
        json.dumps(run_to_jsonable(result, include_raw=False), indent=2, sort_keys=True),
        encoding="utf-8",
    )


def progress(message: str, quiet: bool) -> None:
    if not quiet:
        print(message, file=sys.stderr, flush=True)


def tail(text: str, max_chars: int = 1200) -> str:
    stripped = bench.strip_ansi(text).strip()
    if len(stripped) <= max_chars:
        return stripped
    return stripped[-max_chars:]


def build_run_schedule(args: argparse.Namespace) -> list[tuple[str, int]]:
    cold_runs = min(args.cold_runs, args.runs)
    schedule: list[tuple[str, int]] = []
    for measured_index in range(1, cold_runs + 1):
        schedule.append(("cold", measured_index))
    for warmup_index in range(1, args.warmup + 1):
        schedule.append(("warmup", warmup_index))
    for measured_index in range(cold_runs + 1, args.runs + 1):
        schedule.append(("warm", measured_index))
    return schedule


def run_scenario(args: argparse.Namespace, scenario: Scenario, cwd: str) -> tuple[dict[str, Any], list[RunResult]]:
    command = build_command(args, clean=scenario.clean)
    env = build_env(args)
    results: list[RunResult] = []
    schedule = build_run_schedule(args)
    cold_runs = min(args.cold_runs, args.runs)

    command_display = " ".join(shlex.quote(part) for part in command)
    description = "minimal (--clean)" if scenario.clean else "full config"
    if not args.quiet:
        print(
            f"\n{bench.header(scenario.name, description, PAL)}\n"
            f"  command: {command_display}\n"
            f"  cold: {cold_runs}, warmup: {args.warmup}, warm: {args.runs - cold_runs}",
            flush=True,
        )

    # Dotted-phase progress, uniform with the zsh/neovim TUI: one dot per run
    # ('F' on failure) under a 'cold phase' / 'warm phase' label, with elapsed
    # time. Warmup runs are silent (matching neovim). Phases are scheduled in
    # order (cold, warmup, warm) so we can render them as they change.
    phase_labels = {"cold": "cold phase", "warm": "warm phase"}
    current_phase: str | None = None
    phase_t0 = 0.0

    def close_phase() -> None:
        nonlocal current_phase
        if current_phase in phase_labels and not args.quiet:
            print(f"  ({time.perf_counter() - phase_t0:.1f}s)", flush=True)
        current_phase = None

    for ordinal, (phase, index) in enumerate(schedule, start=1):
        if phase != current_phase:
            close_phase()
            current_phase = phase
            phase_t0 = time.perf_counter()
            if phase in phase_labels and not args.quiet:
                print(f"  {phase_labels[phase]} ", end="", flush=True)

        result = run_once(
            scenario=scenario.name,
            index=index,
            phase=phase,
            command=command,
            env=env,
            cwd=cwd,
            timeout=args.timeout,
        )
        results.append(result)
        if args.raw_dir:
            raw_dir = Path(args.raw_dir) / scenario.name if args.compare_clean else Path(args.raw_dir)
            write_raw_outputs(str(raw_dir), result)

        if phase in phase_labels and not args.quiet:
            print("." if result.ok else "F", end="", flush=True)

        if not result.ok and args.fail_fast:
            break

        if ordinal < len(schedule) and args.sleep_between > 0:
            time.sleep(args.sleep_between)

    close_phase()

    # Surface a few failure tails on stderr (the dots only show 'F'); the report
    # also lists every failure.
    for r in [r for r in results if not r.ok][:3]:
        stderr_tail = tail(r.stderr)
        if stderr_tail:
            progress(f"[{scenario.name}] {r.phase} run #{r.index} failed:\n{stderr_tail}",
                     args.quiet)

    measured = [r for r in results if not r.warmup]
    if not measured:
        raise RuntimeError(f"No measured runs completed for scenario {scenario.name}")

    report = collect_report(args, scenario, command, env, results, resource_counts=None)
    return report, results


def main(argv: list[str]) -> int:
    args = parse_args(argv)
    global PAL
    PAL = bench.make_palette(args)
    try:
        # Validate command/env early; per-scenario command may add/remove --clean flags.
        if not shlex.split(args.cmd):
            raise ValueError("--cmd parsed to an empty command")
        build_env(args)
    except ValueError as exc:
        print(f"error: {exc}", file=sys.stderr)
        return 2

    cwd = str(Path(args.cwd).expanduser().resolve())
    if not Path(cwd).is_dir():
        print(f"error: --cwd does not exist or is not a directory: {cwd}", file=sys.stderr)
        return 2

    reports: list[dict[str, Any]] = []
    all_results: list[RunResult] = []
    scenarios = scenario_list(args)
    for scenario in scenarios:
        try:
            report, results = run_scenario(args, scenario, cwd)
        except (RuntimeError, ValueError) as exc:
            print(f"error: {exc}", file=sys.stderr)
            return 1
        reports.append(report)
        all_results.extend(results)

    # Resource counting intentionally happens after all timed scenarios, so the
    # SDK helper cannot warm any scenario's timed cold/first run.
    count_env = build_env(args)
    for scenario, report in zip(scenarios, reports):
        progress(f"[{scenario.name}] Collecting resource counts...", args.quiet or args.no_resource_counts)
        report["resource_counts"] = collect_resource_counts(args, scenario, count_env, cwd)

    for index, report in enumerate(reports):
        print(render_report(report, top_stages=args.top_stages))
        if index != len(reports) - 1:
            print("\n")

    comparison = build_comparison(reports) if args.compare_clean else None
    if comparison:
        print("\n" + render_comparison(comparison))

    compile_cache = (
        run_compile_cache_comparison(args, cwd, args.compile_cache_runs)
        if args.compile_cache else None
    )
    if compile_cache:
        print("\n" + render_compile_cache(compile_cache))

    print("\n" + render_legend(measured_internal=True))

    final_report: dict[str, Any]
    if args.compare_clean:
        final_report = {
            "mode": "compare-clean",
            "reports": reports,
            "comparison": comparison,
        }
    else:
        final_report = reports[0]
    if compile_cache:
        final_report["compile_cache"] = compile_cache

    measured_all = [r for r in all_results if not r.warmup]
    if args.json_out:
        bench.write_json(args.json_out, final_report, sort_keys=True)
        progress(f"Wrote JSON report: {args.json_out}", args.quiet)
    if args.csv_out:
        write_csv(args.csv_out, measured_all)
        progress(f"Wrote CSV report: {args.csv_out}", args.quiet)

    total_successes = sum(report["measured_successes"] for report in reports)
    total_failures = sum(report["measured_failures"] for report in reports)
    if total_successes == 0:
        return 1
    return 0 if total_failures == 0 else 1


if __name__ == "__main__":
    try:
        raise SystemExit(main(sys.argv[1:]))
    except KeyboardInterrupt:
        sys.exit(130)
