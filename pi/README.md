# Pi (stow package)

This stow package manages public-safe Pi config files.

## Managed paths

- `~/.pi/agent/settings.json`
- `~/.pi/agent/extensions/answer.ts` (`/answer`)
- `~/.pi/agent/extensions/minimal-mode.ts` (`Ctrl+O`, `/minimal-mode`)
- `~/.pi/agent/extensions/startup-header.ts` (custom startup header)
- `~/.pi/agent/extensions/goal.ts` (`/goal` autonomous completion condition; tune the evaluator with `PI_GOAL_MODEL` and the autonomous-loop safety caps with `PI_GOAL_MAX_TURNS` (default 50) / `PI_GOAL_MAX_COST` (default $15, `0` disables))
- `~/.pi/agent/extensions/search-prompts.ts` (`Ctrl+R`, `/search-prompts` prompt history search)
- `~/.pi/agent/extensions/effort.ts` (`/effort`, and `/settings` search alias for thinking level)
- `~/.pi/agent/vendor/pi-web-access/` (vendored local `pi-web-access` package, including committed runtime `node_modules/`)
- `~/.pi/agent/vendor/pi-ask-user/` (vendored local `pi-ask-user` package; peers are resolved by Pi's extension loader)

## Excluded (sensitive/local state)

- `~/.pi/agent/auth.json`
- `~/.pi/agent/sessions/`

## Apply

```bash
stow -vt ~ pi
```

If `~/.pi/agent/settings.json` already exists as a regular file, back it up first:

```bash
cp ~/.pi/agent/settings.json ~/.pi/agent/settings.json.bak
rm ~/.pi/agent/settings.json
stow -vt ~ pi
```
