# Benchmarks

Startup-time benchmark suite for the three things this dotfiles repo cares
about: the Zsh shell, Neovim, and the Pi coding agent. Pure-Python, **stdlib
only** (no `pip install`), each script is a standalone executable.

All three share `_bench_common.py` — one TTY-aware color helper, one table
renderer, one stats/percentile implementation, one PTY runner — so the output,
flags, and reported metrics are uniform. Color auto-disables when output is not
a TTY (pipes, files, CI) and honors `NO_COLOR`; force it with `--color` /
`--no-color`.

## Scripts

| Script | Measures | Canonical technique it mirrors |
|--------|----------|-------------------------------|
| `zsh-benchmark.py` | Zsh startup: exit-time, time-to-interactive, per-function profile | hyperfine timing · [zsh-bench](https://github.com/romkatv/zsh-bench) · `zsh/zprof` |
| `neovim-benchmark.py` | Neovim startup, cold vs warm Lua bytecode cache | `nvim --startuptime` under a PTY (UIEnter) · `:Lazy profile` / `rhysd/vim-startuptime` |
| `pi-benchmark.py` | Pi agent startup: wall clock + internal stages, full vs `--clean`, V8 compile cache | hyperfine timing · `NODE_COMPILE_CACHE` |

## Usage

```bash
# Zsh — exit-time (cheap, default), plus the metrics that reflect responsiveness
./zsh-benchmark.py
./zsh-benchmark.py --interactive          # first_prompt_lag / command_lag (zsh-bench style)
./zsh-benchmark.py --profile              # zprof per-function attribution
./zsh-benchmark.py --profile --runs 0     # zprof only

# Neovim — cold/warm startup (cold clears <cache>/luac)
./neovim-benchmark.py
./neovim-benchmark.py --cold-runs 0       # warm only
./neovim-benchmark.py --scenario session --session ~/proj/Session.vim

# Pi — wall clock + internal stage breakdown
./pi-benchmark.py
./pi-benchmark.py --compare-clean         # full config vs --clean
./pi-benchmark.py --compile-cache         # NODE_COMPILE_CACHE cold vs warm (Node >= 22.1)
```

Common flags across all three: `-r/--runs`, `-w/--warmup`, `--json PATH`,
`--cwd`, `--timeout`, `--color`/`--no-color`. Binary overrides via `--zsh` /
`--nvim` / `--cmd` (or `$ZSH_BIN` / `$NVIM_BIN` / `$PI_BENCHMARK_CMD`). Run any
script with `--help` for the full list.

## Metrics

Every run prints a **Legend** defining its terms. The headline is the **median**
(robust on the right-skewed startup distribution); `min` is the noise floor,
`p95` the tail, and `CV` (σ/mean) tells you whether the run was clean enough to
trust — a hyperfine-style ⚠ warning fires when variance is high. `--json` writes
the full sample set (NaN-safe valid JSON) for your own analysis. `pi-benchmark.py`
additionally reports `p90`/`p99` (deeper tail), `IQR` (outlier-robust spread),
and `%total` (per-stage share of internal TOTAL) on top of this shared set; each
script's printed Legend is authoritative.

For a cold OS page cache on macOS, run `sudo purge` before benchmarking (the
analogue of Linux `drop_caches`). Note that `zsh -i -c exit` is an *exit-time
proxy* — it never draws a prompt, so `--interactive` is what actually reflects
how responsive the shell feels.

## Optional aliases

`system/.aliases.d/70-benchmarks.sh` exposes `bench-zsh` / `bench-nvim` /
`bench-pi` shortcuts.
