local map = vim.keymap.set

-- Move to window using the <ctrl> hjkl keys
map("n", "<C-h>", "<C-w>h", { desc = "Go to Left Window", remap = true })
map("n", "<C-j>", "<C-w>j", { desc = "Go to Lower Window", remap = true })
map("n", "<C-k>", "<C-w>k", { desc = "Go to Upper Window", remap = true })
map("n", "<C-l>", "<C-w>l", { desc = "Go to Right Window", remap = true })
map({"n", "x"}, "j", [[v:count || mode(1)[0:1] == "no" ? "j" : "gj"]], {expr = true, remap = true})
map({"n", "x"}, "k", [[v:count || mode(1)[0:1] == "no" ? "k" : "gk"]], {expr = true, remap = true})


if vim.g.vscode then
    -- Remap folding keys
    map('n', 'zM', '<Cmd>call VSCodeNotify("editor.foldAll")<CR>', { noremap = true, silent = true })
    map('n', 'zR', '<Cmd>call VSCodeNotify("editor.unfoldAll")<CR>', { noremap = true, silent = true })
    map('n', 'zc', '<Cmd>call VSCodeNotify("editor.fold")<CR>', { noremap = true, silent = true })
    map('n', 'zC', '<Cmd>call VSCodeNotify("editor.foldRecursively")<CR>', { noremap = true, silent = true })
    map('n', 'zo', '<Cmd>call VSCodeNotify("editor.unfold")<CR>', { noremap = true, silent = true })
    map('n', 'zO', '<Cmd>call VSCodeNotify("editor.unfoldRecursively")<CR>', { noremap = true, silent = true })
    map('n', 'za', '<Cmd>call VSCodeNotify("editor.toggleFold")<CR>', { noremap = true, silent = true })
    map('n', '<leader>fo', '<Cmd>call VSCodeNotify("workbench.action.files.openFile")<CR>', {noremap = true, silent = true})
    map('n', '<C-w>q', '<Cmd>call VSCodeNotify("workbench.action.joinTwoGroups")<CR>', {noremap = true, silent = true})
 end