local model = require("tabterm.model")
local state = require("tabterm.state")

local M = {}
local sidebar_ns = vim.api.nvim_create_namespace("tabterm.sidebar")

local function valid_buf(bufnr)
  return bufnr and bufnr > 0 and vim.api.nvim_buf_is_valid(bufnr)
end

local function valid_win(winid)
  return winid and winid > 0 and vim.api.nvim_win_is_valid(winid)
end

local function config()
  return state.config.ui
end

local function border()
  return config().border == "none" and "none" or config().border
end

function M.setup_highlights()
  pcall(vim.api.nvim_set_hl, 0, "TabtermSidebarNumber", { default = true, link = "Number" })
  pcall(vim.api.nvim_set_hl, 0, "TabtermSidebarCommand", { default = true, link = "String" })
  pcall(vim.api.nvim_set_hl, 0, "TabtermSidebarCwd", { default = true, link = "Directory" })
  pcall(vim.api.nvim_set_hl, 0, "TabtermPanelHeaderMuted", { default = true, link = "Comment" })
  pcall(vim.api.nvim_set_hl, 0, "TabtermPanelHeaderSuccess", { default = true, link = "DiagnosticOk" })
  pcall(vim.api.nvim_set_hl, 0, "TabtermPanelHeaderUnknown", { default = true, link = "DiagnosticInfo" })
  pcall(vim.api.nvim_set_hl, 0, "TabtermPanelHeaderError", { default = true, link = "DiagnosticError" })
  vim.api.nvim_set_hl(0, "TabtermSidebarSuccess", {
    default = true,
    link = "DiagnosticOk",
  })
  vim.api.nvim_set_hl(0, "TabtermSidebarUnknown", {
    default = true,
    link = "DiagnosticInfo",
  })
  vim.api.nvim_set_hl(0, "TabtermSidebarError", {
    default = true,
    link = "DiagnosticError",
  })
  vim.api.nvim_set_hl(0, "TabtermSidebarFade1", {
    default = true,
    link = "Comment",
  })
  vim.api.nvim_set_hl(0, "TabtermSidebarFade2", {
    default = true,
    link = "NonText",
  })
  vim.api.nvim_set_hl(0, "TabtermSidebarHover", {
    default = true,
    link = "Visual",
  })
  pcall(vim.api.nvim_set_hl, 0, "TabtermBackdrop", {
    default = true,
    bg = "#000000",
  })
end

local function float_layout()
  local total_w = math.max(60, math.floor(vim.o.columns * config().float.width))
  local total_h = math.max(12, math.floor(vim.o.lines * config().float.height))
  local row = math.max(1, math.floor((vim.o.lines - total_h) / 2) - 1)
  local col = math.max(0, math.floor((vim.o.columns - total_w) / 2))
  local window_border_extra = border() == "none" and 0 or 2
  local content_budget = math.max(40, total_w - (window_border_extra * 2))
  local sidebar_w = math.min(config().sidebar_width, math.max(20, content_budget - 20))
  local panel_w = math.max(20, content_budget - sidebar_w)
  return {
    row = row,
    col = col,
    total_w = total_w,
    total_h = total_h,
    sidebar_w = sidebar_w,
    panel_w = panel_w,
    panel_col = col + sidebar_w + window_border_extra,
  }
end

local function sidebar_win_config(layout)
  return {
    relative = "editor",
    row = layout.row,
    col = layout.col,
    width = layout.sidebar_w,
    height = layout.total_h,
    style = "minimal",
    border = border(),
    zindex = 100,
  }
end

local function panel_win_config(layout)
  return {
    relative = "editor",
    row = layout.row,
    col = layout.panel_col,
    width = layout.panel_w,
    height = layout.total_h,
    style = "minimal",
    border = border(),
    zindex = 100,
  }
end

local function backdrop_win_config()
  return {
    relative = "editor",
    row = 0,
    col = 0,
    width = vim.o.columns,
    height = vim.o.lines,
    style = "minimal",
    focusable = false,
    zindex = 1,
    noautocmd = true,
  }
end

local function sidebar_keymaps(bufnr)
  local opts = { buffer = bufnr, silent = true, nowait = true }
  vim.keymap.set("n", "<CR>", function()
    require("tabterm").select_sidebar_cursor()
  end, opts)
  vim.keymap.set("n", "a", function()
    require("tabterm").new_shell()
  end, opts)
  vim.keymap.set("n", "c", function()
    require("tabterm").new_command()
  end, opts)
  vim.keymap.set("n", "r", function()
    require("tabterm").rename_sidebar_cursor()
  end, opts)
  vim.keymap.set("n", "d", function()
    require("tabterm").delete_sidebar_cursor()
  end, opts)
  vim.keymap.set("n", "J", function()
    require("tabterm").move_sidebar_cursor(1)
  end, opts)
  vim.keymap.set("n", "K", function()
    require("tabterm").move_sidebar_cursor(-1)
  end, opts)
  vim.keymap.set("n", "q", function()
    require("tabterm").hide()
  end, opts)
  vim.keymap.set("n", "l", function()
    require("tabterm").focus_panel()
  end, opts)
  vim.keymap.set("n", "j", function()
    require("tabterm").sidebar_step(1)
  end, opts)
  vim.keymap.set("n", "k", function()
    require("tabterm").sidebar_step(-1)
  end, opts)
  vim.keymap.set("n", "<Down>", function()
    require("tabterm").sidebar_step(1)
  end, opts)
  vim.keymap.set("n", "<Up>", function()
    require("tabterm").sidebar_step(-1)
  end, opts)
  vim.keymap.set("n", "<C-l>", function()
    require("tabterm").focus_panel()
  end, opts)
end

local function placeholder_keymaps(bufnr)
  local opts = { buffer = bufnr, silent = true, nowait = true }
  vim.keymap.set("n", "<CR>", function()
    require("tabterm").start_active()
  end, opts)
  vim.keymap.set("n", "c", function()
    require("tabterm").new_command()
  end, opts)
  vim.keymap.set("n", "r", function()
    require("tabterm").rename_active()
  end, opts)
  vim.keymap.set("n", "d", function()
    require("tabterm").delete_active()
  end, opts)
  vim.keymap.set("n", "q", function()
    require("tabterm").hide()
  end, opts)
  vim.keymap.set("n", "<C-h>", function()
    require("tabterm").focus_sidebar()
  end, opts)
end

local function terminal_keymaps(bufnr)
  local opts = { buffer = bufnr, silent = true, nowait = true }
  vim.keymap.set({ "n", "t" }, "<C-h>", function()
    require("tabterm").focus_sidebar()
  end, opts)
end

local function set_scratch_options(bufnr, filetype)
  vim.bo[bufnr].buftype = "nofile"
  vim.bo[bufnr].bufhidden = "hide"
  vim.bo[bufnr].swapfile = false
  vim.bo[bufnr].modifiable = true
  vim.bo[bufnr].filetype = filetype
end

local function stl_escape(text)
  text = tostring(text or "")
  text = text:gsub("%%", "%%%%")
  text = text:gsub("[\r\n]", " ")
  text = text:gsub("[%z\1-\31]", "")
  return text
end

local function panel_header_status_hl(terminal)
  local kind = terminal and terminal.snapshot and terminal.snapshot.last_result and terminal.snapshot.last_result.kind or "unknown"
  if kind == "success" then
    return "TabtermPanelHeaderSuccess", "success"
  end
  if kind == "error" then
    return "TabtermPanelHeaderError", "error"
  end
  return "TabtermPanelHeaderUnknown", "finished"
end

local function set_panel_winbar(workspace, terminal)
  if not valid_win(workspace.runtime.panel.winid) then
    return
  end

  if not terminal or terminal.spec.kind ~= "cmd" or terminal.runtime.phase ~= "exited" then
    vim.wo[workspace.runtime.panel.winid].winbar = ""
    return
  end

  local status_hl, status_text = panel_header_status_hl(terminal)
  local command = stl_escape(model.command_label(terminal))
  local cwd = stl_escape(model.cwd_label(terminal))
  local parts = {
    "%#" .. status_hl .. "# ",
    status_text,
    " %*",
  }

  if command ~= "" then
    table.insert(parts, "%#TabtermSidebarCommand#")
    table.insert(parts, command)
    table.insert(parts, "%*")
  end

  if cwd ~= "" then
    table.insert(parts, "%#TabtermPanelHeaderMuted# in %*")
    table.insert(parts, "%#TabtermSidebarCwd#")
    table.insert(parts, cwd)
    table.insert(parts, "%*")
  end

  vim.wo[workspace.runtime.panel.winid].winbar = "%<" .. table.concat(parts)
end

function M.mount(workspace)
  local layout = float_layout()

  if not valid_buf(workspace.runtime.backdrop.bufnr) then
    workspace.runtime.backdrop.bufnr = vim.api.nvim_create_buf(false, true)
    set_scratch_options(workspace.runtime.backdrop.bufnr, "tabterm-backdrop")
    vim.bo[workspace.runtime.backdrop.bufnr].modifiable = false
  end

  local backdrop_win = workspace.runtime.backdrop.winid
  if valid_win(backdrop_win) then
    state.suppress_winclosed[backdrop_win] = true
    pcall(vim.api.nvim_win_close, backdrop_win, true)
    state.suppress_winclosed[backdrop_win] = nil
  end

  workspace.runtime.backdrop.winid = vim.api.nvim_open_win(workspace.runtime.backdrop.bufnr, false, backdrop_win_config())
  vim.wo[workspace.runtime.backdrop.winid].winblend = 60
  vim.wo[workspace.runtime.backdrop.winid].winhighlight = "Normal:TabtermBackdrop"

  if not valid_buf(workspace.runtime.sidebar.bufnr) then
    workspace.runtime.sidebar.bufnr = vim.api.nvim_create_buf(false, true)
    set_scratch_options(workspace.runtime.sidebar.bufnr, "tabterm-sidebar")
    sidebar_keymaps(workspace.runtime.sidebar.bufnr)
  end

  local sidebar_win = workspace.runtime.sidebar.winid
  if valid_win(sidebar_win) then
    state.suppress_winclosed[sidebar_win] = true
    pcall(vim.api.nvim_win_close, sidebar_win, true)
    state.suppress_winclosed[sidebar_win] = nil
  end

  workspace.runtime.sidebar.winid = vim.api.nvim_open_win(workspace.runtime.sidebar.bufnr, false, sidebar_win_config(layout))

  local panel_buf = workspace.runtime.panel.bufnr
  if not valid_buf(panel_buf) then
    panel_buf = vim.api.nvim_create_buf(false, true)
    set_scratch_options(panel_buf, "tabterm-placeholder")
    placeholder_keymaps(panel_buf)
  end
  workspace.runtime.panel.bufnr = panel_buf

  local panel_win = workspace.runtime.panel.winid
  if valid_win(panel_win) then
    state.suppress_winclosed[panel_win] = true
    pcall(vim.api.nvim_win_close, panel_win, true)
    state.suppress_winclosed[panel_win] = nil
  end

  workspace.runtime.panel.winid = vim.api.nvim_open_win(panel_buf, false, panel_win_config(layout))

  workspace.runtime.visible = true
end

function M.relayout(workspace)
  if not workspace or not workspace.runtime.visible then
    return
  end

  if not valid_win(workspace.runtime.backdrop.winid) or not valid_win(workspace.runtime.sidebar.winid) or not valid_win(workspace.runtime.panel.winid) then
    M.mount(workspace)
    return
  end

  local layout = float_layout()
  vim.api.nvim_win_set_config(workspace.runtime.backdrop.winid, backdrop_win_config())
  vim.api.nvim_win_set_config(workspace.runtime.sidebar.winid, sidebar_win_config(layout))
  vim.api.nvim_win_set_config(workspace.runtime.panel.winid, panel_win_config(layout))
end

function M.unmount(workspace)
  if not workspace then
    return
  end

  for _, winid in ipairs({ workspace.runtime.backdrop.winid, workspace.runtime.sidebar.winid, workspace.runtime.panel.winid }) do
    if valid_win(winid) then
      state.suppress_winclosed[winid] = true
      pcall(vim.api.nvim_win_close, winid, true)
      state.suppress_winclosed[winid] = nil
    end
  end
end

function M.ensure_open(workspace)
  if not workspace.runtime.visible or not valid_win(workspace.runtime.sidebar.winid) or not valid_win(workspace.runtime.panel.winid) then
    M.mount(workspace)
  end
end

function M.render_sidebar(workspace)
  if not valid_buf(workspace.runtime.sidebar.bufnr) then
    return
  end

  local width = valid_win(workspace.runtime.sidebar.winid) and vim.api.nvim_win_get_width(workspace.runtime.sidebar.winid) or config().sidebar_width
  local lines, line_map, decorations = model.sidebar_lines(workspace, width)
  workspace.runtime.sidebar.line_map = line_map

  vim.bo[workspace.runtime.sidebar.bufnr].modifiable = true
  vim.api.nvim_buf_set_lines(workspace.runtime.sidebar.bufnr, 0, -1, false, lines)
  vim.bo[workspace.runtime.sidebar.bufnr].modifiable = false
  vim.api.nvim_buf_clear_namespace(workspace.runtime.sidebar.bufnr, sidebar_ns, 0, -1)

  for _, decoration in ipairs(decorations) do
    vim.api.nvim_buf_add_highlight(
      workspace.runtime.sidebar.bufnr,
      sidebar_ns,
      decoration.hl,
      decoration.line,
      decoration.start_col,
      decoration.end_col
    )
  end

  local row = nil
  if valid_win(workspace.runtime.sidebar.winid) then
    local target_row = nil
    local active_terminal_id = workspace.active_terminal_id
    if active_terminal_id then
      for index, id in ipairs(line_map) do
        if id == active_terminal_id then
          target_row = index
          break
        end
      end
    end

    if target_row then
      local current_row = vim.api.nvim_win_get_cursor(workspace.runtime.sidebar.winid)[1]
      if current_row ~= target_row then
        vim.api.nvim_win_set_cursor(workspace.runtime.sidebar.winid, { target_row, 0 })
      end
      row = target_row
    else
      row = vim.api.nvim_win_get_cursor(workspace.runtime.sidebar.winid)[1]
    end
  end

  local terminal_id = row and line_map[row] or nil
  if terminal_id then
    for index, id in ipairs(line_map) do
      if id == terminal_id then
        vim.api.nvim_buf_add_highlight(workspace.runtime.sidebar.bufnr, sidebar_ns, "TabtermSidebarHover", index - 1, 0, -1)
      end
    end
  end

  if valid_win(workspace.runtime.sidebar.winid) then
    vim.wo[workspace.runtime.sidebar.winid].cursorline = false
  end
end

function M.render_placeholder(workspace)
  if not valid_win(workspace.runtime.panel.winid) then
    return
  end

  set_panel_winbar(workspace, nil)

  local buf = workspace.runtime.panel.bufnr
  if not valid_buf(buf) or vim.bo[buf].buftype == "terminal" then
    buf = vim.api.nvim_create_buf(false, true)
    set_scratch_options(buf, "tabterm-placeholder")
    placeholder_keymaps(buf)
    workspace.runtime.panel.bufnr = buf
  end

  local placeholder = model.placeholder_model(workspace)
  local lines = {
    placeholder.title or "",
  }

  if placeholder.context and placeholder.context ~= "" then
    table.insert(lines, placeholder.context)
  end
  if placeholder.status and placeholder.status ~= "" then
    local detail = placeholder.detail and placeholder.detail ~= "" and ("  " .. placeholder.detail) or ""
    table.insert(lines, placeholder.status .. detail)
  elseif placeholder.detail and placeholder.detail ~= "" then
    table.insert(lines, placeholder.detail)
  end
  if placeholder.hint and placeholder.hint ~= "" then
    table.insert(lines, "")
    table.insert(lines, placeholder.hint)
  end

  vim.api.nvim_win_set_buf(workspace.runtime.panel.winid, buf)
  vim.bo[buf].modifiable = true
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].modifiable = false
  vim.api.nvim_win_set_cursor(workspace.runtime.panel.winid, { 1, 0 })
end

function M.render_panel(workspace)
  if workspace.runtime.panel.kind == "terminal" then
    local terminal = workspace.active_terminal_id and workspace.terminals_by_id[workspace.active_terminal_id] or nil
    if terminal and valid_win(workspace.runtime.panel.winid) and valid_buf(terminal.runtime.bufnr) then
      workspace.runtime.panel.bufnr = terminal.runtime.bufnr
      vim.api.nvim_win_set_buf(workspace.runtime.panel.winid, terminal.runtime.bufnr)
      vim.bo[terminal.runtime.bufnr].bufhidden = "hide"
      set_panel_winbar(workspace, terminal)
    end
    return
  end

  M.render_placeholder(workspace)
end

function M.refresh(workspace)
  if not workspace or not workspace.runtime.visible then
    return
  end

  M.render_sidebar(workspace)
  M.render_panel(workspace)
end

function M.start_terminal(workspace, terminal)
  M.ensure_open(workspace)

  if terminal.runtime.bufnr and valid_buf(terminal.runtime.bufnr) then
    pcall(vim.api.nvim_buf_delete, terminal.runtime.bufnr, { force = true })
  end

  local bufnr = vim.api.nvim_create_buf(false, true)
  terminal.runtime.bufnr = bufnr
  workspace.runtime.panel.bufnr = bufnr
  vim.bo[bufnr].bufhidden = "hide"
  terminal_keymaps(bufnr)
  vim.api.nvim_win_set_buf(workspace.runtime.panel.winid, bufnr)

  local job_cmd
  if terminal.spec.kind == "shell" then
    job_cmd = { terminal.spec.cmd }
  else
    job_cmd = { vim.o.shell, "-c", terminal.spec.cmd }
  end

  local channel_id = vim.api.nvim_win_call(workspace.runtime.panel.winid, function()
    vim.api.nvim_set_current_buf(bufnr)
    return vim.fn.jobstart(job_cmd, {
      term = true,
      cwd = terminal.spec.cwd,
    })
  end)

  return bufnr, channel_id
end

return M
