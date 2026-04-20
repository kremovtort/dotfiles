local M = {}

local function tail(path)
  path = tostring(path or "")
  if path == "" then
    return ""
  end
  return vim.fn.fnamemodify(path, ":t")
end

local function normalize_title(title, fallback_cmd, cwd_tail)
  title = tostring(title or "")

  if title == "" then
    title = tostring(fallback_cmd or "")
  end

  if cwd_tail ~= "" and (title == cwd_tail or title:find(cwd_tail, 1, true)) then
    title = tail(vim.env.SHELL or "")
  end

  if title:sub(1, 5) == "/nix/" then
    title = tail(title)
  end

  if title == "" then
    title = "term"
  end

  return title
end

local function strip_trailing_slash(path)
  path = tostring(path or "")
  if path == "/" then
    return path
  end
  return (path:gsub("/+$", ""))
end

local function effective_tabpage_cwd(tabpage)
  local ok, cwd = pcall(vim.api.nvim_tabpage_call, tabpage, function()
    return strip_trailing_slash((vim.uv or vim.loop).cwd() or vim.fn.getcwd())
  end)
  if ok then
    return cwd
  end
  return strip_trailing_slash((vim.uv or vim.loop).cwd() or vim.fn.getcwd())
end

local function truncate_display(text, max_width)
  text = tostring(text or "")
  max_width = math.max(0, max_width or 0)
  if max_width == 0 or text == "" then
    return "", false
  end

  if vim.fn.strdisplaywidth(text) <= max_width then
    return text, false
  end

  local chars = vim.fn.strchars(text)
  while chars > 0 do
    local candidate = vim.fn.strcharpart(text, 0, chars)
    if vim.fn.strdisplaywidth(candidate) <= max_width then
      return candidate, true
    end
    chars = chars - 1
  end

  return "", true
end

local function pad_display_right(text, width)
  text = tostring(text or "")
  width = math.max(0, width or 0)
  local display_width = vim.fn.strdisplaywidth(text)
  if display_width >= width then
    return text
  end
  return text .. string.rep(" ", width - display_width)
end

local function maybe_shorten_path(path, max_width)
  path = tostring(path or "")
  if path == "" then
    return ""
  end

  if vim.fn.strdisplaywidth(path) <= max_width then
    return path
  end

  local is_absolute = path:sub(1, 1) == "/"
  local parts = vim.split(path, "/", { plain = true, trimempty = true })
  if #parts <= 1 then
    return path
  end

  for index = 1, #parts - 1 do
    local part = parts[index]
    if part ~= "" then
      parts[index] = vim.fn.strcharpart(part, 0, 1)
    end
  end

  local shortened = table.concat(parts, "/")
  if is_absolute then
    shortened = "/" .. shortened
  end
  return shortened
end

function M.new_workspace(tabpage)
  return {
    active_terminal_id = nil,
    terminal_order = {},
    terminals_by_id = {},
    runtime = {
      tabpage = tabpage,
      visible = false,
      last_editor_winid = nil,
      next_terminal_seq = 1,
      sidebar = {
        bufnr = nil,
        winid = nil,
        line_map = {},
      },
      backdrop = {
        bufnr = nil,
        winid = nil,
      },
      panel = {
        kind = "placeholder",
        bufnr = nil,
        winid = nil,
      },
    },
  }
end

function M.new_terminal(id, spec)
  spec = spec or {}
  local kind = spec.kind == "cmd" and "cmd" or "shell"
  local cmd = spec.cmd or (kind == "shell" and (vim.env.SHELL or vim.o.shell or "sh") or "")
  local cwd = spec.cwd or (vim.uv or vim.loop).cwd() or vim.fn.getcwd()

  return {
    id = id,
    spec = {
      kind = kind,
      cmd = cmd,
      cwd = cwd,
      name_override = spec.name_override,
      restore = "manual",
    },
    snapshot = {
      title = spec.title,
      cwd = cwd,
      last_result = {
        kind = "unknown",
        code = nil,
        source = "unknown",
      },
      last_output_line = nil,
      notification = {
        unread = false,
        kind = "unknown",
        line = nil,
      },
    },
    runtime = {
      phase = "dormant",
      bufnr = nil,
      winid = nil,
      channel_id = nil,
      command = {
        integration = "none",
        phase = "unknown",
        output_tail = nil,
      },
    },
  }
end

function M.ensure_terminal_shape(id, terminal)
  if not terminal then
    terminal = M.new_terminal(id, {})
  end

  terminal.id = id
  terminal.spec = vim.tbl_deep_extend("force", M.new_terminal(id, {}).spec, terminal.spec or {})
  terminal.snapshot = vim.tbl_deep_extend("force", M.new_terminal(id, { cwd = terminal.spec.cwd }).snapshot, terminal.snapshot or {})
  terminal.runtime = vim.tbl_deep_extend("force", M.new_terminal(id, {}).runtime, terminal.runtime or {})
  terminal.runtime.command = vim.tbl_deep_extend("force", M.new_terminal(id, {}).runtime.command, terminal.runtime.command or {})

  if not terminal.snapshot.cwd or terminal.snapshot.cwd == "" then
    terminal.snapshot.cwd = terminal.spec.cwd
  end

  return terminal
end

function M.display_name(terminal)
  if not terminal then
    return "term"
  end

  if terminal.spec.name_override and terminal.spec.name_override ~= "" then
    return terminal.spec.name_override
  end

  local cwd_tail = tail(terminal.snapshot.cwd or terminal.spec.cwd)
  local title = normalize_title(terminal.snapshot.title, terminal.spec.cmd, cwd_tail)

  if cwd_tail ~= "" then
    return cwd_tail .. " " .. title
  end

  return title
end

function M.context_line(terminal)
  if not terminal then
    return ""
  end

  local cwd_tail = tail(terminal.snapshot.cwd or terminal.spec.cwd)
  local cmd = tostring(terminal.spec.cmd or "")

  if cmd:sub(1, 5) == "/nix/" then
    cmd = tail(cmd)
  end

  if cwd_tail ~= "" and cmd ~= "" then
    return cwd_tail .. "  " .. cmd
  end
  if cwd_tail ~= "" then
    return cwd_tail
  end
  return cmd
end

function M.command_label(terminal)
  if not terminal then
    return "term"
  end

  if terminal.spec.name_override and terminal.spec.name_override ~= "" then
    return terminal.spec.name_override
  end

  if terminal.spec.kind == "shell" then
    local cwd_tail = tail(terminal.snapshot.cwd or terminal.spec.cwd)
    return normalize_title(terminal.snapshot.title, terminal.spec.cmd, cwd_tail)
  end

  local cmd = tostring(terminal.spec.cmd or "")
  if cmd == "" then
    return "term"
  end

  if cmd:sub(1, 5) == "/nix/" then
    return tail(cmd)
  end

  if not cmd:find(" ", 1, true) and cmd:find("/", 1, true) then
    return tail(cmd)
  end

  return cmd
end

function M.cwd_label(terminal)
  if not terminal then
    return ""
  end

  return tostring(terminal.snapshot.cwd or terminal.spec.cwd or "")
end

local function format_cwd_label(workspace, terminal, max_width)
  local cwd = strip_trailing_slash(M.cwd_label(terminal))
  if cwd == "" then
    return "", false
  end

  local base = workspace and workspace.runtime and workspace.runtime.tabpage and effective_tabpage_cwd(workspace.runtime.tabpage) or strip_trailing_slash((vim.uv or vim.loop).cwd() or vim.fn.getcwd())

  if base ~= "" then
    if cwd == base then
      cwd = "-/"
    elseif cwd:sub(1, #base + 1) == base .. "/" then
      cwd = "-/" .. cwd:sub(#base + 2)
    end
  end

  if cwd ~= "-/" then
    cwd = strip_trailing_slash(cwd)
  end
  if cwd == "" then
    cwd = tail(base)
  end

  cwd = maybe_shorten_path(cwd, max_width)
  return truncate_display(cwd, max_width)
end

function M.is_waiting(terminal)
  if not terminal or terminal.runtime.phase ~= "live" then
    return false
  end

  if terminal.spec.kind == "cmd" then
    return true
  end

  return terminal.runtime.command.phase == "running"
end

function M.result_label(terminal)
  if M.is_waiting(terminal) then
    return "waiting"
  end

  local result = terminal and terminal.snapshot and terminal.snapshot.last_result or nil
  local kind = result and result.kind or "unknown"

  if kind == "success" then
    return "success"
  end
  if kind == "error" then
    return "error"
  end
  if terminal and terminal.runtime.phase == "dormant" then
    return "not started"
  end
  if terminal and terminal.runtime.phase == "exited" then
    return "finished"
  end
  return "unknown"
end

function M.sidebar_badge(terminal)
  if not terminal then
    return nil
  end

  if M.is_waiting(terminal) then
    return {
      text = "…",
      hl = "TabtermSidebarUnknown",
    }
  end

  local notification = terminal.snapshot and terminal.snapshot.notification or nil
  if not notification or not notification.unread then
    return nil
  end

  if notification.kind == "error" then
    return {
      text = "●",
      hl = "TabtermSidebarError",
    }
  end

  if notification.kind == "success" then
    return {
      text = "●",
      hl = "TabtermSidebarSuccess",
    }
  end

  return {
    text = "●",
    hl = "TabtermSidebarUnknown",
  }
end

function M.detail_line(terminal)
  if not terminal then
    return ""
  end

  local detail = terminal.snapshot.last_output_line
  if detail and detail ~= "" then
    return detail
  end

  if terminal.runtime.phase == "exited" and terminal.snapshot.last_result.code ~= nil then
    return ("exited with code %d"):format(terminal.snapshot.last_result.code)
  end

  return M.context_line(terminal)
end

function M.sidebar_lines(workspace, width)
  local lines = {}
  local line_map = {}
  local decorations = {}
  width = math.max(8, width or 30)

  for index, id in ipairs(workspace.terminal_order) do
    local terminal = workspace.terminals_by_id[id]
    if terminal then
      local prefix = ("%d "):format(index)
      local badge = M.sidebar_badge(terminal)
      local badge_width = badge and vim.fn.strdisplaywidth(badge.text) or 0
      local command_max_width = math.max(1, width - vim.fn.strdisplaywidth(prefix) - badge_width)
      local command, truncated = truncate_display(M.command_label(terminal), command_max_width)
      local title = prefix .. command

      if truncated then
        local chars = vim.fn.strchars(command)
        if chars >= 2 then
          local fade1_char = chars - 2
          local fade2_char = chars - 1
          local command_start = #prefix
          table.insert(decorations, {
            line = #lines,
            start_col = command_start + vim.str_byteindex(command, fade1_char),
            end_col = command_start + vim.str_byteindex(command, fade1_char + 1),
            hl = "TabtermSidebarFade1",
          })
          table.insert(decorations, {
            line = #lines,
            start_col = command_start + vim.str_byteindex(command, fade2_char),
            end_col = command_start + #command,
            hl = "TabtermSidebarFade2",
          })
        elseif chars == 1 then
          table.insert(decorations, {
            line = #lines,
            start_col = #prefix,
            end_col = #prefix + #command,
            hl = "TabtermSidebarFade2",
          })
        end
      end

      if badge then
        title = pad_display_right(title, math.max(0, width - badge_width)) .. badge.text
        table.insert(decorations, {
          line = #lines,
          start_col = #title - #badge.text,
          end_col = #title,
          hl = badge.hl,
        })
      else
        title = pad_display_right(title, width)
      end
      table.insert(lines, title)
      table.insert(line_map, id)

      local cwd_prefix = "  "
      local cwd, cwd_truncated = format_cwd_label(workspace, terminal, math.max(1, width - vim.fn.strdisplaywidth(cwd_prefix)))
      local cwd_line = pad_display_right(cwd_prefix .. cwd, width)
      table.insert(lines, cwd_line)
      table.insert(line_map, id)

      if cwd_truncated then
        local chars = vim.fn.strchars(cwd)
        if chars >= 2 then
          local fade1_char = chars - 2
          local fade2_char = chars - 1
          local line = #lines - 1
          local start = #cwd_prefix
          table.insert(decorations, {
            line = line,
            start_col = start + vim.str_byteindex(cwd, fade1_char),
            end_col = start + vim.str_byteindex(cwd, fade1_char + 1),
            hl = "TabtermSidebarFade1",
          })
          table.insert(decorations, {
            line = line,
            start_col = start + vim.str_byteindex(cwd, fade2_char),
            end_col = start + #cwd,
            hl = "TabtermSidebarFade2",
          })
        elseif chars == 1 then
          table.insert(decorations, {
            line = #lines - 1,
            start_col = #cwd_prefix,
            end_col = #cwd_line,
            hl = "TabtermSidebarFade2",
          })
        end
      end
    end
  end

  if #lines == 0 then
    table.insert(lines, "No terminals")
    table.insert(line_map, false)
  end

  return lines, line_map, decorations
end

function M.placeholder_model(workspace)
  local id = workspace.active_terminal_id
  local terminal = id and workspace.terminals_by_id[id] or nil

  if not terminal then
    return {
      kind = workspace.active_terminal_id == nil and "empty" or "inconsistent",
      title = workspace.active_terminal_id == nil and "No terminals in this tab" or "Terminal state is unavailable",
      context = nil,
      status = nil,
      detail = workspace.active_terminal_id == nil and "Create a shell or command terminal" or "Select another terminal or reopen the workspace",
      hint = workspace.active_terminal_id == nil and "<CR> new shell   c new command" or "q close",
    }
  end

  if terminal.runtime.phase == "dormant" then
    return {
      kind = "dormant",
      title = M.display_name(terminal),
      context = M.context_line(terminal),
      status = "not started",
      detail = nil,
      hint = "<CR> start   r rename   d delete",
    }
  end

  if terminal.runtime.phase == "exited" then
    return {
      kind = "exited",
      title = M.display_name(terminal),
      context = M.context_line(terminal),
      status = M.result_label(terminal),
      detail = M.detail_line(terminal),
      hint = "<CR> start again   r rename   d delete",
    }
  end

  return {
    kind = "inconsistent",
    title = M.display_name(terminal),
    context = M.context_line(terminal),
    status = nil,
    detail = "Terminal is not mounted in the panel",
    hint = "q close",
  }
end

return M
