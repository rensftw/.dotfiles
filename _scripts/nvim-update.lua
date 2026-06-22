-- Headless Neovim updater for the `tend` alias.
-- Updates lazy.nvim plugins that have NO breaking changes; lists the rest for
-- manual review. Refreshes Mason and updates its tools. Never opens the UI.

local out = io.stdout
local c = { red = "\27[31m", grn = "\27[32m", yel = "\27[33m",
            cyan = "\27[36m", mag = "\27[35m", dim = "\27[2m", bold = "\27[1m", off = "\27[0m" }
local function say(s) out:write(s .. "\n") end
local function short(sha) return sha and sha:sub(1, 7) or "?" end

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
  -- We print our own summary, so silence lazy's headless task/log/process output.
  local h = Config.options.headless
  h.task, h.log, h.process = false, false, false

  manage.check({ wait = true, show = false })   -- fetch only, don't apply

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

  if #safe == 0 and #review == 0 then
    say(c.grn .. "  ✔ all up to date" .. c.off)
  end

  if #safe > 0 then
    local names = {}
    for _, e in ipairs(safe) do names[#names + 1] = e.name end
    manage.update({ plugins = names, wait = true, show = false })   -- safe subset only
    say(c.grn .. ("  ✔ updated %d:"):format(#safe) .. c.off)
    for _, e in ipairs(safe) do
      say(("     %s%-26s%s %s%s (%d)%s"):format(c.cyan, e.name, c.off, c.dim, e.range, e.n, c.off))
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
  local notify = vim.notify           -- silence Mason's notifications; we print our own
  vim.notify = function() end
  pcall(function()
    require("lazy").load({ plugins = { "mason.nvim", "mason-lspconfig.nvim", "mason-tool-installer.nvim" } })
  end)
  local reg = pcall(vim.cmd, "MasonUpdate")            -- blocks in headless
  local tools = pcall(vim.cmd, "MasonToolsUpdateSync") -- blocks until done
  vim.notify = notify
  say((reg and c.grn .. "  ✔ registry refreshed" or c.yel .. "  • registry refresh skipped") .. c.off)
  say((tools and c.grn .. "  ✔ tools updated" or c.yel .. "  • tool update skipped") .. c.off)

  ---------------------------------------------------------------- Treesitter
  header("Neovim Treesitter")
  -- Parsers are managed by tree-sitter-manager.nvim (nvim-treesitter is archived).
  -- The plugin pins every parser to a git revision in its repos.lua, so a parser
  -- only changes when the plugin itself is bumped. We force-rebuild the installed
  -- set only when the lazy step above updated the plugin — a daily run otherwise
  -- recompiles ~40 parsers for no change. Installs are async (vim.system); we
  -- block until they finish, the way Mason's *Sync variants do.
  local ts_bumped = false
  for _, e in ipairs(safe) do
    if e.name == "tree-sitter-manager.nvim" then ts_bumped = true end
  end

  vim.notify = function() end           -- installer is chatty; we print our own summary
  local ts_ok, ts_err = pcall(function()
    require("lazy").load({ plugins = { "tree-sitter-manager.nvim" } })
    local installer = require("tree-sitter-manager.installer")
    local repos     = require("tree-sitter-manager.repos")
    local util      = require("tree-sitter-manager.util")

    local langs = {}
    for lang in pairs(repos) do
      if vim.uv.fs_stat(util.ppath(lang)) then langs[#langs + 1] = lang end
    end

    if not ts_bumped then
      say(c.grn .. ("  ✔ %d parsers at pinned revisions (plugin unchanged)"):format(#langs) .. c.off)
      return
    end

    table.sort(langs)
    local pending, failed = #langs, {}
    for _, lang in ipairs(langs) do
      -- setup() cached {ok=true} for every installed parser, and the installer
      -- filters on that cache (installer.lua:127) BEFORE it honours `force`, so
      -- clear it first or nothing reinstalls. force=true then bypasses the
      -- is_installed check; no_deps=true keeps exactly one callback per call so the
      -- pending counter stays exact.
      installer.status[lang] = nil
      installer.install(lang, function(out)
        pending = pending - 1
        if not (out and out.ok) then failed[#failed + 1] = lang end
      end, true, true)
    end
    vim.wait(300000, function() return pending <= 0 end, 200)   -- pumps the loop for async jobs

    if pending > 0 then
      say(c.yel .. ("  • timed out — %d parser(s) still building"):format(pending) .. c.off)
    else
      say(c.grn .. ("  ✔ rebuilt %d parsers"):format(#langs - #failed) .. c.off)
    end
    if #failed > 0 then
      table.sort(failed)
      say(c.yel .. ("  ⚠ %d failed: "):format(#failed) .. table.concat(failed, " ") .. c.off)
    end
  end)
  vim.notify = notify
  if not ts_ok then say(c.red .. "  ✗ treesitter error: " .. tostring(ts_err) .. c.off) end
end)

if not ok then out:write(c.red .. "  updater error: " .. tostring(err) .. c.off .. "\n") end
out:flush()
