-- Headless Neovim updater for the `tend` alias.
-- Updates lazy.nvim plugins that have NO breaking changes; lists the rest for
-- manual review. Refreshes Mason and updates its tools. Never opens the UI.
-- Exits non-zero (:cquit) when any section fails, so tend's failure
-- aggregation can report the neovim task.

local out = io.stdout
local c = { red = "\27[31m", grn = "\27[32m", yel = "\27[33m",
            cyan = "\27[36m", mag = "\27[35m", dim = "\27[2m", bold = "\27[1m", off = "\27[0m" }
local function say(s) out:write(s .. "\n") end
local function short(sha) return sha and sha:sub(1, 7) or "?" end

-- Sections that failed; non-empty at the end → exit non-zero.
local failed_sections = {}
local function mark_failed(section)
  for _, s in ipairs(failed_sections) do
    if s == section then return end
  end
  failed_sections[#failed_sections + 1] = section
end

-- Whitespace-collapsed, capped for one-line display.
local function brief(msg, max)
  msg = vim.trim((tostring(msg or ""):gsub("%s+", " ")))
  max = max or 100
  return #msg > max and msg:sub(1, max - 1) .. "…" or msg
end

-- tree-sitter-manager's util errors are "<command line>\n<stderr>"; the
-- command prefix alone exceeds a display line, so show the stderr part.
local function res_brief(res)
  local msg = (res and res.error) or "unknown error"
  local stderr = msg:match("\n(.*)")
  if stderr and stderr:match("%S") then msg = stderr end
  return brief(msg)
end

-- Section header: figlet "digital" in rainbow (lolcat). --force because our
-- stdout here is a captured pipe, not a TTY. Falls back to plain coloured text.
local function header(text)
  local art = vim.fn.system({ "sh", "-c",
    "figlet -f digital " .. vim.fn.shellescape(text) .. " | lolcat --force" })
  if vim.v.shell_error == 0 and art:match("%S") then
    out:write("\n" .. art)
  else
    out:write("\n" .. c.bold .. c.mag .. "  " .. text .. c.off .. "\n")
  end
end

local ok, err = pcall(function()
  --------------------------------------------------------------- Lazy plugins
  header("Neovim Lazy")

  local Config = require("lazy.core.config")
  local manage = require("lazy.manage")
  -- We print our own summary, so silence lazy's headless task/log/process
  -- output. That makes each plugin's ERROR-level task log the only failure
  -- record; lazy_errors() reads it back out after check/update.
  local h = Config.options.headless
  h.task, h.log, h.process = false, false, false

  -- ERROR-level task output (git.fetch, git.checkout, build, …) per plugin.
  local function lazy_errors(only)
    local errs = {}
    for name, plugin in pairs(Config.plugins) do
      if not only or only[name] then
        for _, task in ipairs(plugin._ and plugin._.tasks or {}) do
          if task:has_errors() then
            local msg = task:output(vim.log.levels.ERROR)
            errs[name] = errs[name] and (errs[name] .. "; " .. msg) or msg
          end
        end
      end
    end
    return errs
  end

  local function say_plugin_errors(errs)
    local names = vim.tbl_keys(errs)
    table.sort(names)
    for _, name in ipairs(names) do
      say(("     %s%-26s%s %s%s%s"):format(c.red, name, c.off, c.dim, brief(errs[name]), c.off))
    end
  end

  manage.check({ wait = true, show = false })   -- fetch only, don't apply

  local check_errs = lazy_errors()
  if next(check_errs) then
    mark_failed("lazy")
    say(c.red .. ("  ✗ check failed for %d:"):format(vim.tbl_count(check_errs)) .. c.off)
    say_plugin_errors(check_errs)
  end

  local safe, review = {}, {}
  for name, plugin in pairs(Config.plugins) do
    local u = plugin._ and plugin._.updates
    local from = u and u.from and u.from.commit
    local to = u and u.to and u.to.commit
    if from and to and from ~= to then
      local log = vim.fn.systemlist(
        { "git", "-C", plugin.dir, "log", "--no-merges", "--format=%h %s", from .. ".." .. to })
      local entry = { name = name, range = short(from) .. " → " .. short(to), n = #log, breaking = {} }
      if vim.v.shell_error ~= 0 then
        entry.breaking = { "could not inspect commits" }
      else
        -- Conventional-commit breaking marker "type(scope)!:" — lazy's own rule.
        for _, l in ipairs(log) do
          if l:find("^%w+ %S+!:") then entry.breaking[#entry.breaking + 1] = l end
        end
      end
      if #entry.breaking > 0 then table.insert(review, entry) else table.insert(safe, entry) end
    end
  end
  table.sort(safe, function(a, b) return a.name < b.name end)
  table.sort(review, function(a, b) return a.name < b.name end)

  if #safe == 0 and #review == 0 and not next(check_errs) then
    say(c.grn .. "  ✔ all up to date" .. c.off)
  end

  local updated = {}
  if #safe > 0 then
    local names, safe_set = {}, {}
    for _, e in ipairs(safe) do
      names[#names + 1] = e.name
      safe_set[e.name] = true
    end
    manage.update({ plugins = names, wait = true, show = false })   -- safe subset only

    -- manage.update cleared the safe plugins' check tasks, so errors here are
    -- from the update run itself; anything listed failed to actually apply.
    local update_errs = lazy_errors(safe_set)
    for _, e in ipairs(safe) do
      if not update_errs[e.name] then updated[#updated + 1] = e end
    end

    if #updated > 0 then
      say(c.grn .. ("  ✔ updated %d:"):format(#updated) .. c.off)
      for _, e in ipairs(updated) do
        say(("     %s%-26s%s %s%s (%d)%s"):format(c.cyan, e.name, c.off, c.dim, e.range, e.n, c.off))
      end
    end
    if next(update_errs) then
      mark_failed("lazy")
      say(c.red .. ("  ✗ update failed for %d:"):format(#safe - #updated) .. c.off)
      say_plugin_errors(update_errs)
    end
  end

  if #review > 0 then
    say(c.yel .. c.bold .. "  ⚠ held back — breaking changes, update manually:" .. c.off)
    for _, e in ipairs(review) do
      say(("     %s%-26s%s %s%s%s"):format(c.yel, e.name, c.off, c.dim, e.range, c.off))
      for _, l in ipairs(e.breaking) do say("        " .. c.dim .. "• " .. l .. c.off) end
      say("        " .. c.dim .. "↳ :Lazy update " .. e.name .. c.off)
    end
  end

  --------------------------------------------------------------------- Mason
  header("Neovim Mason")
  -- Mason and mason-tool-installer report failures via vim.notify(..., ERROR)
  -- without raising, so the pcall results alone can't see them — record
  -- ERROR-level notifications (and silence the rest; we print our own).
  local notify = vim.notify
  local mason_errs = {}
  vim.notify = function(msg, level)
    if level == vim.log.levels.ERROR then mason_errs[#mason_errs + 1] = tostring(msg) end
  end
  pcall(function()
    require("lazy").load({ plugins = { "mason.nvim", "mason-lspconfig.nvim", "mason-tool-installer.nvim" } })
  end)
  local reg = pcall(vim.cmd, "MasonUpdate")            -- blocks in headless
  local reg_err_count = #mason_errs
  local tools = pcall(vim.cmd, "MasonToolsUpdateSync") -- blocks until done
  vim.notify = notify

  reg = reg and reg_err_count == 0
  tools = tools and #mason_errs == reg_err_count
  say((reg and c.grn .. "  ✔ registry refreshed" or c.red .. "  ✗ registry refresh failed") .. c.off)
  say((tools and c.grn .. "  ✔ tools updated" or c.red .. "  ✗ tool update failed") .. c.off)
  for _, m in ipairs(mason_errs) do
    say("     " .. c.red .. "• " .. c.off .. c.dim .. brief(m) .. c.off)
  end
  if not (reg and tools) then mark_failed("mason") end

  ---------------------------------------------------------------- Treesitter
  header("Neovim Treesitter")
  -- Parsers are managed by tree-sitter-manager.nvim (nvim-treesitter is archived).
  -- The plugin pins every parser to a git revision in its repos.lua, so a parser
  -- only changes when the plugin itself is bumped. We rebuild the installed set
  -- when this run bumped the plugin (and the bump actually applied), when
  -- `tend --force` sets TEND_FORCE_TS, or when a previous rebuild is still
  -- pending — a daily run otherwise recompiles ~40 parsers for no change.
  -- Installs are async (vim.system); we block until they finish, the way Mason's
  -- *Sync variants do.
  local ts_bumped, ts_range = false, nil
  for _, e in ipairs(updated) do
    if e.name == "tree-sitter-manager.nvim" then ts_bumped, ts_range = true, e.range end
  end
  local ts_force = vim.env.TEND_FORCE_TS == "1"   -- `tend --force`: rebuild even without a plugin bump

  -- A rebuild that fails, times out, or is interrupted must survive the bump
  -- gate closing: it is recorded in this marker file and retried on every run
  -- until one completes clean.
  local ts_marker = vim.fs.joinpath(vim.fn.stdpath("state"), "tend-ts-rebuild-pending")
  local ts_pending = nil
  local mf = io.open(ts_marker, "r")
  if mf then
    ts_pending = mf:read("*l") or "unfinished rebuild"
    mf:close()
  end

  vim.notify = function() end           -- installer is chatty; we print our own summary
  local ts_ok, ts_err = pcall(function()
    -- Installs run `git` and `tree-sitter` via vim.system, which throws
    -- ENOENT from a vim.schedule callback — outside any pcall here — when a
    -- binary is missing; the pending counter then never drains and vim.wait
    -- blocks for its full timeout. Check up front, before the plugin's
    -- setup() can kick off installs of its own.
    for _, bin in ipairs({ "git", "tree-sitter" }) do
      if vim.fn.executable(bin) ~= 1 then
        say(c.red .. ("  ✗ `%s` not on PATH — skipping treesitter step"):format(bin) .. c.off)
        mark_failed("treesitter")
        return
      end
    end

    require("lazy").load({ plugins = { "tree-sitter-manager.nvim" } })
    local installer = require("tree-sitter-manager.installer")  -- also populates backport._install_single (installer.lua:179)
    local backport  = require("tree-sitter-manager.backport")
    local repos     = require("tree-sitter-manager.repos")
    local util      = require("tree-sitter-manager.util")

    -- setup() (run by the load above) already kicked off async installs for
    -- any missing ensure_installed parsers, tracked in installer.installing /
    -- installer.status. Wait for them — otherwise the trailing qa! exits nvim
    -- with clones/builds still in flight — and count their failures.
    local missing = {}
    if not vim.tbl_isempty(installer.installing) then
      missing = vim.tbl_keys(installer.installing)
      table.sort(missing)
      say(("  %sinstalling %d missing:%s %s"):format(c.bold, #missing, c.off, table.concat(missing, " ")))
      vim.wait(300000, function() return vim.tbl_isempty(installer.installing) end, 100)
    end
    for _, lang in ipairs(missing) do
      local st = installer.status[lang]
      if st and st.ok then
        say(("     %s✓%s %s%-16s%s %sinstalled%s"):format(c.grn, c.off, c.cyan, lang, c.off, c.dim, c.off))
      end
    end
    local ensure_failed = {}
    for lang, st in pairs(installer.status) do
      if not st.ok then ensure_failed[#ensure_failed + 1] = { lang = lang, msg = res_brief(st) } end
    end
    for lang in pairs(installer.installing) do
      ensure_failed[#ensure_failed + 1] = { lang = lang, msg = "install timed out" }
    end
    if #ensure_failed > 0 then
      mark_failed("treesitter")
      table.sort(ensure_failed, function(a, b) return a.lang < b.lang end)
      for _, e in ipairs(ensure_failed) do
        say(("     %s✗%s %s%-16s%s %s%s%s"):format(c.red, c.off, c.cyan, e.lang, c.off, c.dim, e.msg, c.off))
      end
    end

    local langs = {}
    for lang in pairs(repos) do
      if vim.uv.fs_stat(util.ppath(lang)) then langs[#langs + 1] = lang end
    end
    table.sort(langs)

    -- `cause` is what the marker stores; the retry prefix is display-only so
    -- repeated retries don't stack prefixes in the marker file.
    local cause = ts_bumped and ("tree-sitter-manager.nvim " .. ts_range)
      or ts_force and "forced rebuild"
      or ts_pending
    if not cause then
      say(c.grn .. ("  ✔ %d parsers at pinned revisions (plugin unchanged)"):format(#langs) .. c.off)
      return
    end
    local reason = cause == ts_pending and ("retry: " .. ts_pending) or cause

    -- Persist the pending rebuild before starting: if this run fails, times
    -- out, or is killed, tomorrow's run retries even though the bump gate no
    -- longer fires. Removed only after a fully clean rebuild.
    mf = io.open(ts_marker, "w")
    if mf then
      mf:write(cause, "\n")
      mf:close()
    else
      say(c.yel .. "  • could not write rebuild marker " .. ts_marker .. c.off)
    end

    -- Force a rebuild via the installer's private single-install (exposed as
    -- backport._install_single). Unlike installer.install(), it skips the
    -- is_installed() short-circuit — which otherwise returns without ever calling
    -- our callback for an already-present parser — and it builds in place
    -- (`tree-sitter build -o <parser>`) instead of deleting first, so a failed
    -- build leaves the old parser intact. No dependency expansion, so exactly one
    -- callback fires per call and the pending counter stays exact.
    local install_one = backport._install_single
    if not install_one then
      say(c.red .. "  ✗ rebuild needed but the single-install hook is gone (plugin dropped backport._install_single) — update this script" .. c.off)
      mark_failed("treesitter")
      return
    end

    say(("  %srebuilding %d parsers%s  %s(%s)%s"):format(
      c.bold, #langs, c.off, c.dim, reason, c.off))

    local start = vim.uv.hrtime()
    local pending, done, failed_langs = #langs, {}, {}
    for _, lang in ipairs(langs) do
      local info = util.get_repo_info(lang)
      local rev  = info and (info.revision and short(info.revision) or info.branch) or "—"
      install_one(lang, function(res)
        pending = pending - 1
        done[lang] = true
        if res and res.ok then
          local secs = (vim.uv.hrtime() - start) / 1e9
          say(("     %s✓%s %s%-16s%s %s%-8s (%.1fs)%s"):format(
            c.grn, c.off, c.cyan, lang, c.off, c.dim, rev, secs, c.off))
        else
          failed_langs[#failed_langs + 1] = lang
          say(("     %s✗%s %s%-16s%s %s%-8s %s%s"):format(
            c.red, c.off, c.cyan, lang, c.off, c.dim, rev, res_brief(res), c.off))
        end
      end)
    end
    vim.wait(300000, function() return pending <= 0 end, 100)   -- pumps the loop for async jobs

    local timed_out = {}
    for _, lang in ipairs(langs) do
      if not done[lang] then timed_out[#timed_out + 1] = lang end
    end

    local built = #langs - #failed_langs - #timed_out
    say(c.grn .. ("  ✔ rebuilt %d/%d"):format(built, #langs) .. c.off)
    if #failed_langs > 0 then
      table.sort(failed_langs)
      say(c.yel .. ("  ⚠ %d failed: "):format(#failed_langs) .. table.concat(failed_langs, " ") .. c.off)
    end
    if #timed_out > 0 then
      table.sort(timed_out)
      say(c.yel .. ("  • %d timed out: "):format(#timed_out) .. table.concat(timed_out, " ") .. c.off)
    end
    if #failed_langs == 0 and #timed_out == 0 then
      os.remove(ts_marker)
    else
      mark_failed("treesitter")
      say(c.yel .. "  ⚠ rebuild left pending — will retry on the next run" .. c.off)
    end
    say("  " .. c.dim .. "legend: rev = pinned grammar revision · time = since rebuild start" .. c.off)
  end)
  vim.notify = notify
  if not ts_ok then
    say(c.red .. "  ✗ treesitter error: " .. tostring(ts_err) .. c.off)
    mark_failed("treesitter")
  end
end)

if not ok then
  out:write(c.red .. "  updater error: " .. tostring(err) .. c.off .. "\n")
  mark_failed("updater")
end
if #failed_sections > 0 then
  out:write(c.red .. c.bold .. "\n  ✗ failed: " .. table.concat(failed_sections, ", ") .. c.off .. "\n")
  out:flush()
  vim.cmd("cquit! 1")   -- non-zero exit so tend records the neovim task as failed
end
out:flush()
