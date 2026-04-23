if vim.g.loaded_tabterm_plugin == 1 then
	return
end

vim.g.loaded_tabterm_plugin = 1

vim.api.nvim_create_user_command("TabtermToggle", function()
	require("tabterm").toggle()
end, {})

vim.api.nvim_create_user_command("TabtermOpen", function()
	require("tabterm").open()
end, {})

vim.api.nvim_create_user_command("TabtermClose", function()
	require("tabterm").hide()
end, {})

vim.api.nvim_create_user_command("TabtermNewShell", function()
	require("tabterm").new_shell()
end, {})

---@class tabterm.UserCommandArgs
---@field args string

---@param opts tabterm.UserCommandArgs
local function tabterm_new_command(opts)
	require("tabterm").new_command(opts.args ~= "" and opts.args or nil)
end

vim.api.nvim_create_user_command("TabtermNewCommand", tabterm_new_command, {
	nargs = "?",
})

vim.api.nvim_create_user_command("TabtermStart", function()
	require("tabterm").start_active()
end, {})

vim.api.nvim_create_user_command("TabtermRename", function()
	require("tabterm").rename_active()
end, {})

vim.api.nvim_create_user_command("TabtermDelete", function()
	require("tabterm").delete_active()
end, {})

vim.api.nvim_create_user_command("TabtermNext", function()
	require("tabterm").next_terminal()
end, {})

vim.api.nvim_create_user_command("TabtermPrev", function()
	require("tabterm").prev_terminal()
end, {})
