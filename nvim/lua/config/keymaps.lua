if vim.g.vscode then
  local function vscode(command)
    return '<Cmd>call VSCodeNotify("' .. command .. '")<CR>'
  end
  
  local noremap_silent = { noremap = true, silent = true }

  -- Remap folding keys
  vim.keymap.set("n", "zM", vscode("editor.foldAll"), noremap_silent)
  vim.keymap.set("n", "zR", vscode("editor.unfoldAll"), noremap_silent)
  vim.keymap.set("n", "zc", vscode("editor.fold"), noremap_silent)
  vim.keymap.set("n", "zC", vscode("editor.foldRecursively"), noremap_silent)
  vim.keymap.set("n", "zo", vscode("editor.unfold"), noremap_silent)
  vim.keymap.set("n", "zO", vscode("editor.unfoldRecursively"), noremap_silent)
  vim.keymap.set("n", "za", vscode("editor.toggleFold"), noremap_silent)
  
  -- Remap error navigation keys
  vim.keymap.set("n", "]e", vscode("editor.action.marker.next"), noremap_silent)
  vim.keymap.set("n", "[e", vscode("editor.action.marker.prev"), noremap_silent)
  vim.keymap.set("n", "]E", vscode("editor.action.marker.nextInFiles"), noremap_silent)
  vim.keymap.set("n", "[E", vscode("editor.action.marker.prevInFiles"), noremap_silent)
  vim.keymap.set("n", "<C-w>q", vscode("workbench.action.closeEditorsInGroup"), noremap_silent)
  vim.keymap.set("n", "<leader>e", vscode("workbench.files.action.focusFilesExplorer"), noremap_silent)

  -- Remap navigation keys
  vim.keymap.set("n", "gr", vscode("editor.action.goToReferences"), noremap_silent)
  vim.keymap.set("n", "gi", vscode("editor.action.goToImplementation"), noremap_silent)
  vim.keymap.set("n", "gt", vscode("editor.action.goToTypeDefinition"), noremap_silent)
  
  vim.keymap.set("n", "<leader>m", vscode("haskell-modules.search"), noremap_silent)
  vim.keymap.set("n", "<leader>s", vscode("workbench.action.gotoSymbol"), noremap_silent)
  vim.keymap.set("n", "<leader>S", vscode("workbench.action.showAllSymbols"), noremap_silent)
  
  return
end

-- ============================================================================
-- LazyVim "General" keymaps (ported, without LazyVim dependencies)
-- Source: http://www.lazyvim.org/keymaps#general
-- ============================================================================

local function map(mode, lhs, rhs, opts)
  opts = opts or {}
  opts.silent = opts.silent ~= false
  vim.keymap.set(mode, lhs, rhs, opts)
end

-- Better up/down for wrapped lines (and keep counts working)
map({ "n", "x" }, "j", function()
  return vim.v.count == 0 and "gj" or "j"
end, { expr = true, desc = "Down" })
map({ "n", "x" }, "<Down>", function()
  return vim.v.count == 0 and "gj" or "j"
end, { expr = true, desc = "Down" })
map({ "n", "x" }, "k", function()
  return vim.v.count == 0 and "gk" or "k"
end, { expr = true, desc = "Up" })
map({ "n", "x" }, "<Up>", function()
  return vim.v.count == 0 and "gk" or "k"
end, { expr = true, desc = "Up" })

-- Window navigation
map("n", "<C-h>", "<C-w>h", { desc = "Go to Left Window" })
map("n", "<C-j>", "<C-w>j", { desc = "Go to Lower Window" })
map("n", "<C-k>", "<C-w>k", { desc = "Go to Upper Window" })
map("n", "<C-l>", "<C-w>l", { desc = "Go to Right Window" })

-- Resize windows
map("n", "<C-Up>", "<cmd>resize +2<cr>", { desc = "Increase Window Height" })
map("n", "<C-Down>", "<cmd>resize -2<cr>", { desc = "Decrease Window Height" })
map("n", "<C-Left>", "<cmd>vertical resize -2<cr>", { desc = "Decrease Window Width" })
map("n", "<C-Right>", "<cmd>vertical resize +2<cr>", { desc = "Increase Window Width" })

-- Move lines
map({ "n", "i", "v" }, "<A-j>", "<cmd>m .+1<cr>==", { desc = "Move Down" })
map({ "n", "i", "v" }, "<A-k>", "<cmd>m .-2<cr>==", { desc = "Move Up" })
map("v", "<A-j>", ":m '>+1<cr>gv=gv", { desc = "Move Down" })
map("v", "<A-k>", ":m '<-2<cr>gv=gv", { desc = "Move Up" })
map("i", "<A-j>", "<esc><cmd>m .+1<cr>==gi", { desc = "Move Down" })
map("i", "<A-k>", "<esc><cmd>m .-2<cr>==gi", { desc = "Move Up" })

-- Buffer navigation
map("n", "<S-h>", "<cmd>bprevious<cr>", { desc = "Prev Buffer" })
map("n", "<S-l>", "<cmd>bnext<cr>", { desc = "Next Buffer" })
map("n", "[b", "<cmd>bprevious<cr>", { desc = "Prev Buffer" })
map("n", "]b", "<cmd>bnext<cr>", { desc = "Next Buffer" })
map("n", "<leader>bb", "<cmd>buffer #<cr>", { desc = "Switch to Other Buffer" })
map("n", "<leader>`", "<cmd>buffer #<cr>", { desc = "Switch to Other Buffer" })

local function buf_delete(bufnr)
  bufnr = bufnr or 0
  -- If modified, keep consistent behavior: ask via builtin confirm when possible.
  if vim.bo[bufnr].modified then
    local choice = vim.fn.confirm("Buffer modified. Delete anyway?", "&Yes\n&No", 2)
    if choice ~= 1 then
      return
    end
  end
  vim.api.nvim_buf_delete(bufnr, { force = true })
end

map("n", "<leader>bd", function()
  buf_delete(0)
end, { desc = "Delete Buffer" })

map("n", "<leader>bo", function()
  local current = vim.api.nvim_get_current_buf()
  for _, b in ipairs(vim.api.nvim_list_bufs()) do
    if b ~= current and vim.api.nvim_buf_is_loaded(b) and vim.bo[b].buflisted then
      pcall(vim.api.nvim_buf_delete, b, { force = true })
    end
  end
end, { desc = "Delete Other Buffers" })

map("n", "<leader>bD", function()
  local win = vim.api.nvim_get_current_win()
  buf_delete(0)
  pcall(vim.api.nvim_win_close, win, true)
end, { desc = "Delete Buffer and Window" })

-- Escape and clear search highlight
map({ "i", "n", "s" }, "<esc>", function()
  vim.cmd("nohlsearch")
  return "<esc>"
end, { expr = true, desc = "Escape and Clear hlsearch" })

map("n", "<leader>ur", function()
  vim.cmd("nohlsearch")
  vim.cmd("diffupdate")
  vim.cmd("redraw")
end, { desc = "Redraw / Clear hlsearch / Diff Update" })

-- Better search result navigation
map({ "n", "x", "o" }, "n", "nzzzv", { desc = "Next Search Result" })
map({ "n", "x", "o" }, "N", "Nzzzv", { desc = "Prev Search Result" })

-- Save file
map({ "i", "x", "n", "s" }, "<C-s>", "<cmd>silent! write<cr>", { desc = "Save File" })

-- Keywordprg (same as default `K`)
map("n", "<leader>K", "<cmd>normal! K<cr>", { desc = "Keywordprg" })

-- Comment helpers (gco / gcO)
local function comment_prefix()
  local cs = vim.bo.commentstring
  if not cs or cs == "" or not cs:find("%%s") then
    return "# "
  end
  local pre = cs:match("^(.-)%%s") or ""
  pre = pre:gsub("%s+$", "")
  return pre ~= "" and (pre .. " ") or ""
end

map("n", "gco", function()
  local row = vim.api.nvim_win_get_cursor(0)[1]
  vim.api.nvim_buf_set_lines(0, row, row, true, { comment_prefix() })
  vim.api.nvim_win_set_cursor(0, { row + 1, #comment_prefix() })
  vim.cmd("startinsert!")
end, { desc = "Add Comment Below" })

map("n", "gcO", function()
  local row = vim.api.nvim_win_get_cursor(0)[1]
  vim.api.nvim_buf_set_lines(0, row - 1, row - 1, true, { comment_prefix() })
  vim.api.nvim_win_set_cursor(0, { row, #comment_prefix() })
  vim.cmd("startinsert!")
end, { desc = "Add Comment Above" })

-- New file
map("n", "<leader>fn", "<cmd>enew<cr>", { desc = "New File" })

-- Location list / Quickfix list
local function toggle_list(kind)
  for _, win in ipairs(vim.fn.getwininfo()) do
    if kind == "qf" and win.quickfix == 1 and win.loclist == 0 then
      vim.cmd("cclose")
      return
    end
    if kind == "loc" and win.loclist == 1 then
      vim.cmd("lclose")
      return
    end
  end
  if kind == "qf" then
    vim.cmd("copen")
  else
    vim.cmd("lopen")
  end
end

map("n", "<leader>xl", function()
  toggle_list("loc")
end, { desc = "Location List" })
map("n", "<leader>xq", function()
  toggle_list("qf")
end, { desc = "Quickfix List" })
map("n", "[q", "<cmd>cprevious<cr>", { desc = "Previous Quickfix" })
map("n", "]q", "<cmd>cnext<cr>", { desc = "Next Quickfix" })

-- LSP / diagnostics
map({ "n", "x" }, "<leader>cf", function()
  vim.lsp.buf.format({ async = true })
end, { desc = "Format" })
map("n", "<leader>cd", function()
  vim.diagnostic.open_float(nil, { scope = "line" })
end, { desc = "Line Diagnostics" })

map("n", "]d", function()
  vim.diagnostic.goto_next()
end, { desc = "Next Diagnostic" })
map("n", "[d", function()
  vim.diagnostic.goto_prev()
end, { desc = "Prev Diagnostic" })
map("n", "]e", function()
  vim.diagnostic.goto_next({ severity = vim.diagnostic.severity.ERROR })
end, { desc = "Next Error" })
map("n", "[e", function()
  vim.diagnostic.goto_prev({ severity = vim.diagnostic.severity.ERROR })
end, { desc = "Prev Error" })
map("n", "]w", function()
  vim.diagnostic.goto_next({ severity = vim.diagnostic.severity.WARN })
end, { desc = "Next Warning" })
map("n", "[w", function()
  vim.diagnostic.goto_prev({ severity = vim.diagnostic.severity.WARN })
end, { desc = "Prev Warning" })

-- Toggles (subset of LazyVim toggles that are built-in)
local function toggle_opt(opt)
  vim.o[opt] = not vim.o[opt]
end

map("n", "<leader>us", function()
  toggle_opt("spell")
end, { desc = "Toggle Spelling" })
map("n", "<leader>uw", function()
  toggle_opt("wrap")
end, { desc = "Toggle Wrap" })
map("n", "<leader>uL", function()
  toggle_opt("relativenumber")
end, { desc = "Toggle Relative Number" })
map("n", "<leader>ul", function()
  toggle_opt("number")
end, { desc = "Toggle Line Numbers" })
map("n", "<leader>uc", function()
  vim.o.conceallevel = vim.o.conceallevel == 0 and 2 or 0
end, { desc = "Toggle Conceal Level" })
map("n", "<leader>uA", function()
  vim.o.showtabline = vim.o.showtabline == 0 and 2 or 0
end, { desc = "Toggle Tabline" })
map("n", "<leader>ub", function()
  vim.o.background = vim.o.background == "dark" and "light" or "dark"
end, { desc = "Toggle Dark Background" })
map("n", "<leader>ua", function()
  vim.g.snacks_animate = not vim.g.snacks_animate
end, { desc = "Toggle Animations" })

map("n", "<leader>ud", function()
  local enabled = vim.g._kremovtort_diag_enabled
  if enabled == nil then
    enabled = true
  end
  enabled = not enabled
  vim.g._kremovtort_diag_enabled = enabled
  vim.diagnostic.enable(enabled)
end, { desc = "Toggle Diagnostics" })

map("n", "<leader>uh", function()
  local ok = pcall(function()
    local enabled = vim.lsp.inlay_hint.is_enabled({ bufnr = 0 })
    vim.lsp.inlay_hint.enable(not enabled, { bufnr = 0 })
  end)
  if not ok then
    vim.notify("Inlay hints not supported in this Neovim/LSP setup", vim.log.levels.WARN)
  end
end, { desc = "Toggle Inlay Hints" })

-- Terminal window navigation (useful with Snacks terminal too).
local function term_win_nav(dir)
  return function()
    local keys = "<C-\\><C-n><C-w>" .. dir
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(keys, true, false, true), "n", false)
  end
end

vim.keymap.set("t", "<C-h>", term_win_nav("h"), { silent = true, desc = "Go to Left Window" })
vim.keymap.set("t", "<C-j>", term_win_nav("j"), { silent = true, desc = "Go to Lower Window" })
vim.keymap.set("t", "<C-k>", term_win_nav("k"), { silent = true, desc = "Go to Upper Window" })
vim.keymap.set("t", "<C-l>", term_win_nav("l"), { silent = true, desc = "Go to Right Window" })

vim.keymap.set("t", "<C-x>", "<C-\\><C-n>")

local function toggle_edgy(side)
  return function()
    -- Ensure the plugin is loaded (it is an optional plugin under nixCats).
    pcall(require("lze").trigger_load, "edgy.nvim")
    local ok, edgy = pcall(require, "edgy")
    if ok then
      edgy.toggle(side)
    end
  end
end

vim.keymap.set({ "n", "x", "o", "i" }, "<C-x><C-[>", toggle_edgy("left"), { desc = "Toggle edgy.nvim (left)" })
vim.keymap.set({ "n", "x", "o", "i" }, "<C-x><C-]>", toggle_edgy("right"), { desc = "Toggle edgy.nvim (right)" })
vim.keymap.set({ "n", "x", "o", "i" }, "<C-x><C-'>", toggle_edgy("bottom"), { desc = "Toggle edgy.nvim (bottom)" })
