local M = {}

local uv = vim.uv or vim.loop

local function trim(s)
  return (s or ""):gsub("^%s+", ""):gsub("%s+$", "")
end

local function now_ms()
  if uv and uv.hrtime then
    return math.floor(uv.hrtime() / 1e6)
  end
  return math.floor(vim.fn.reltimefloat(vim.fn.reltime()) * 1000)
end

local function is_dir(path)
  if not path or path == "" then
    return false
  end
  if not uv or not uv.fs_stat then
    return vim.fn.isdirectory(path) == 1
  end
  local stat = uv.fs_stat(path)
  return stat and stat.type == "directory" or false
end

local function normalize_dir(path)
  path = tostring(path or "")
  if path == "" then
    return ""
  end

  -- Expand only when needed (avoid vim.fn in hot paths).
  if not path:find("~", 1, true) and not path:find("$", 1, true) then
    return path
  end

  -- Expand ~ and env vars, but avoid forcing :p on non-path strings.
  local expanded = vim.fn.expand(path)
  if expanded == "" then
    return path
  end
  return expanded
end

local function fallback_cwd()
  do
    local ok, cwd = pcall(vim.fn.getcwd)
    if ok then
      cwd = normalize_dir(cwd)
      if is_dir(cwd) then
        return cwd
      end
    end
  end

  local home = normalize_dir(vim.env.HOME or "")
  if is_dir(home) then
    return home
  end

  return "/"
end

local function safe_refresh_lualine()
  pcall(require("lualine").refresh)
end

local function norm_bufnr(bufnr)
  bufnr = bufnr or 0
  if bufnr == 0 then
    return vim.api.nvim_get_current_buf()
  end
  return bufnr
end

local function buf_context_dir(bufnr)
  bufnr = norm_bufnr(bufnr)

  if not vim.api.nvim_buf_is_valid(bufnr) then
    return fallback_cwd()
  end

  local bt = vim.bo[bufnr].buftype
  if bt == "terminal" then
    local bufname = vim.api.nvim_buf_get_name(bufnr)
    local cwd = bufname:match("^term://(.-)//%d+:")
    if cwd and cwd ~= "" then
      cwd = normalize_dir(cwd)
      if is_dir(cwd) then
        return cwd
      end
    end
    return fallback_cwd()
  end

  local name = vim.api.nvim_buf_get_name(bufnr)
  if name ~= "" and not name:find("://", 1, true) then
    local dir = vim.fs.dirname(name)
    if dir and dir ~= "" then
      dir = normalize_dir(dir)
      if is_dir(dir) then
        return dir
      end
    end
  end

  return fallback_cwd()
end

local function find_root(source, markers)
  local ok, root = pcall(vim.fs.root, source, markers)
  if ok and root and root ~= "" then
    return root
  end
end

local function system_async(cmd, opts, cb)
  if vim.in_fast_event and vim.in_fast_event() then
    -- vim.system() callbacks run in fast-event context; schedule any follow-up
    -- system calls back onto the main loop.
    local cmd2 = vim.deepcopy(cmd)
    local opts2 = opts and vim.deepcopy(opts) or nil
    vim.schedule(function()
      system_async(cmd2, opts2, cb)
    end)
    return
  end

  opts = opts or {}
  opts.text = true
  if opts.cwd then
    opts.cwd = normalize_dir(opts.cwd)
    if not is_dir(opts.cwd) then
      opts.cwd = fallback_cwd()
    end
  else
    -- If Neovim's current cwd is invalid (e.g. after unmount), vim.system can error.
    opts.cwd = fallback_cwd()
  end

  local ok, err = pcall(function()
    vim.system(cmd, opts, function(res)
      cb(trim(res.stdout), res.code, res)
    end)
  end)

  if not ok then
    cb("", 127, { stderr = tostring(err) })
  end
end

local function json_decode(s)
  if vim.json and vim.json.decode then
    return pcall(vim.json.decode, s)
  end
  return pcall(vim.fn.json_decode, s)
end

local arc_exe = nil
local function has_arc()
  if arc_exe == nil then
    arc_exe = (vim.fn.executable("arc") == 1)
  end
  return arc_exe
end

local cache = {}
local running = {}

local CACHE_TTL_MS = 1500

local function cache_key(vcs, root)
  return vcs .. ":" .. root
end

local function set_buf_branch(bufnr, branch)
  -- vim.system callbacks run in fast-event context; schedule UI/state updates.
  vim.schedule(function()
    bufnr = norm_bufnr(bufnr)
    if not vim.api.nvim_buf_is_valid(bufnr) then
      return
    end

    if branch == "" then
      branch = nil
    end

    vim.b[bufnr].__lualine_branch = branch
    safe_refresh_lualine()
  end)
end

local function update_git_branch(bufnr, root)
  local key = cache_key("git", root)
  local entry = cache[key]
  local t = now_ms()

  if entry and entry.branch and (t - (entry.ts or 0)) < CACHE_TTL_MS then
    set_buf_branch(bufnr, entry.branch)
    return
  end

  if running[key] then
    if entry and entry.branch then
      set_buf_branch(bufnr, entry.branch)
    end
    return
  end

  running[key] = true

  system_async({ "git", "symbolic-ref", "--short", "-q", "HEAD" }, { cwd = root }, function(out, code)
    if code == 0 and out ~= "" then
      cache[key] = { branch = out, ts = now_ms() }
      running[key] = nil
      set_buf_branch(bufnr, out)
      return
    end

    system_async({ "git", "rev-parse", "--short", "HEAD" }, { cwd = root }, function(sha, code2)
      local b = (code2 == 0 and sha ~= "") and sha or "git"
      cache[key] = { branch = b, ts = now_ms() }
      running[key] = nil
      set_buf_branch(bufnr, b)
    end)
  end)
end

local function update_arc_branch(bufnr, root)
  local key = cache_key("arc", root)
  local entry = cache[key]
  local t = now_ms()

  if entry and entry.branch and (t - (entry.ts or 0)) < CACHE_TTL_MS then
    set_buf_branch(bufnr, entry.branch)
    return
  end

  if running[key] then
    if entry and entry.branch then
      set_buf_branch(bufnr, entry.branch)
    end
    return
  end

  running[key] = true

  system_async({ "arc", "info", "--json" }, { cwd = root }, function(out, code)
    local b = "arc"

    if code == 0 and out ~= "" then
      local ok, obj = json_decode(out)
      if ok and type(obj) == "table" then
        local br = obj.branch
        if type(br) == "string" and br ~= "" then
          b = br
        end
      end
    end

    cache[key] = { branch = b, ts = now_ms() }
    running[key] = nil
    set_buf_branch(bufnr, b)
  end)
end

local function update_jj_branch(bufnr, root)
  local key = cache_key("jj", root)
  local entry = cache[key]
  local t = now_ms()

  if entry and entry.branch and (t - (entry.ts or 0)) < CACHE_TTL_MS then
    set_buf_branch(bufnr, entry.branch)
    return
  end

  if running[key] then
    if entry and entry.branch then
      set_buf_branch(bufnr, entry.branch)
    end
    return
  end

  running[key] = true

  system_async({
    "jj",
    "log",
    "-r",
    "heads(::@ & bookmarks())",
    "-T",
    "bookmarks.map(|b| b.name()).join('\\n')",
    "--no-graph",
    "-n",
    "1",
  }, { cwd = root }, function(out, code)
    if code ~= 0 then
      cache[key] = { branch = "jj", ts = now_ms() }
      running[key] = nil
      set_buf_branch(bufnr, "jj")
      return
    end

    local bookmark = (out:match("([^\n]+)") or "")
    if bookmark == "" then
      cache[key] = { branch = "jj", ts = now_ms() }
      running[key] = nil
      set_buf_branch(bufnr, "jj")
      return
    end

    system_async({ "jj", "log", "--count", "-r", (bookmark .. "..@") }, { cwd = root }, function(count_str)
      local count = tonumber(count_str) or 0
      local b = (count > 0) and (bookmark .. "~" .. tostring(count)) or bookmark
      cache[key] = { branch = b, ts = now_ms() }
      running[key] = nil
      set_buf_branch(bufnr, b)
    end)
  end)
end

function M.update(bufnr)
  bufnr = norm_bufnr(bufnr)

  if not vim.api.nvim_buf_is_valid(bufnr) then
    return
  end

  local src = buf_context_dir(bufnr)

  local jj_root = find_root(src, { ".jj" })
  if jj_root then
    update_jj_branch(bufnr, jj_root)
    return
  end

  local git_root = find_root(src, { ".git" })
  if git_root then
    update_git_branch(bufnr, git_root)
    return
  end

  if not has_arc() then
    set_buf_branch(bufnr, nil)
    return
  end

  system_async({ "arc", "rev-parse", "--show-toplevel" }, { cwd = src }, function(out, code)
    if code == 0 and out ~= "" then
      update_arc_branch(bufnr, out)
      return
    end
    set_buf_branch(bufnr, nil)
  end)
end

local scheduled = {}

function M.schedule(bufnr)
  bufnr = norm_bufnr(bufnr)

  if not vim.api.nvim_buf_is_valid(bufnr) then
    return
  end
  if scheduled[bufnr] then
    return
  end
  scheduled[bufnr] = true
  vim.defer_fn(function()
    scheduled[bufnr] = nil
    vim.schedule(function()
      M.update(bufnr)
    end)
  end, 10)
end

function M.get(bufnr)
  bufnr = norm_bufnr(bufnr)
  if not vim.api.nvim_buf_is_valid(bufnr) then
    return ""
  end
  local b = vim.b[bufnr].__lualine_branch
  if type(b) ~= "string" then
    return ""
  end
  return b
end

function M.setup()
  if vim.g.__lualine_branch_setup_done then
    return
  end
  vim.g.__lualine_branch_setup_done = true

  local group = vim.api.nvim_create_augroup("LualineBranch", { clear = true })

  vim.api.nvim_create_autocmd({ "BufEnter", "DirChanged", "VimEnter", "FocusGained" }, {
    group = group,
    callback = function(ev)
      M.schedule(ev.buf)
    end,
  })

  -- Initial value for the current buffer.
  M.schedule(0)
end

return M
