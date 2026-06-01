# Pi (stow package)

This stow package manages public-safe Pi config files.

## Managed paths

- `~/.pi/agent/settings.json`
- `~/.pi/agent/extensions/answer.ts` (`/answer`)
- `~/.pi/agent/extensions/minimal-mode.ts` (`Ctrl+O`, `/minimal-mode`)
- `~/.pi/agent/extensions/startup-header.ts` (custom startup header)
- `~/.pi/agent/extensions/goal.ts` (`/goal` autonomous completion condition)
- `~/.pi/agent/extensions/search-prompts.ts` (`Ctrl+R`, `/search-prompts` prompt history search)

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
