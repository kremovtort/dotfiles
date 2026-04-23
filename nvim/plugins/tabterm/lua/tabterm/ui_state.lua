local M = {
  by_tabpage = {},
  terminal_bufnr = {},
  terminal_id_bufnr = {},
  terminal_winid = {},
  suppress_winclosed = {},
  suppress_bufdelete = {},
}

function M.tab_key(tabpage)
  return tabpage or vim.api.nvim_get_current_tabpage()
end

function M.get(tabpage)
  local key = M.tab_key(tabpage)
  if not M.by_tabpage[key] then
    M.by_tabpage[key] = {
      backdrop = { bufnr = nil, winid = nil },
      sidebar = { bufnr = nil, winid = nil, line_map = {} },
      panel = { kind = "placeholder", bufnr = nil, winid = nil },
    }
  end
  return M.by_tabpage[key]
end

function M.reset(tabpage)
  M.by_tabpage[M.tab_key(tabpage)] = nil
end

function M.set_window(tabpage, role, winid)
  local ui = M.get(tabpage)
  if ui[role] then
    ui[role].winid = winid
  end
end

function M.set_buffer(tabpage, role, bufnr)
  local ui = M.get(tabpage)
  if ui[role] then
    ui[role].bufnr = bufnr
  end
end

function M.set_terminal_buffer(tabpage, terminal_id, bufnr)
  if bufnr and bufnr > 0 then
    M.terminal_bufnr[bufnr] = {
      tabpage = M.tab_key(tabpage),
      terminal_id = terminal_id,
    }
    M.terminal_id_bufnr[terminal_id] = bufnr
  end
end

function M.clear_terminal_buffer(bufnr)
  if bufnr then
    local ref = M.terminal_bufnr[bufnr]
    if ref then
      M.terminal_bufnr[bufnr] = nil
      M.terminal_id_bufnr[ref.terminal_id] = nil
    end
  end
end

function M.get_terminal_bufnr(terminal_id)
  return M.terminal_id_bufnr[terminal_id]
end

function M.lookup_buffer(bufnr)
  return M.terminal_bufnr[bufnr]
end

function M.terminal_refs_for_tabpage(tabpage)
  local refs = {}
  local key = M.tab_key(tabpage)

  for bufnr, ref in pairs(M.terminal_bufnr) do
    if ref.tabpage == key then
      table.insert(refs, {
        bufnr = bufnr,
        tabpage = ref.tabpage,
        terminal_id = ref.terminal_id,
      })
    end
  end

  table.sort(refs, function(left, right)
    if left.terminal_id == right.terminal_id then
      return left.bufnr < right.bufnr
    end
    return left.terminal_id < right.terminal_id
  end)

  return refs
end

function M.set_terminal_winid(terminal_id, winid)
  if winid and winid > 0 then
    M.terminal_winid[terminal_id] = winid
  else
    M.terminal_winid[terminal_id] = nil
  end
end

function M.get_terminal_winid(terminal_id)
  return M.terminal_winid[terminal_id]
end

function M.set_suppress_winclosed(winid)
  if winid then
    M.suppress_winclosed[winid] = true
  end
end

function M.clear_suppress_winclosed(winid)
  if winid then
    M.suppress_winclosed[winid] = nil
  end
end

function M.is_suppress_winclosed(winid)
  return winid and M.suppress_winclosed[winid] == true
end

function M.set_suppress_bufdelete(bufnr)
  if bufnr then
    M.suppress_bufdelete[bufnr] = true
  end
end

function M.clear_suppress_bufdelete(bufnr)
  if bufnr then
    M.suppress_bufdelete[bufnr] = nil
  end
end

function M.is_suppress_bufdelete(bufnr)
  return bufnr and M.suppress_bufdelete[bufnr] == true
end

function M.snapshot(tabpage)
  return M.get(tabpage)
end

return M
