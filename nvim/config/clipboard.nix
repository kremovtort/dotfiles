{ 
  extraConfigLuaPre = ''
    vim.opt.shortmess:append({ W = true, I = true, c = true, C = true })

    if vim.env.SSH_TTY or vim.env.SSH_CONNECTION then
      vim.o.clipboard = "unnamedplus"

      local function paste()
        return {
          vim.fn.split(vim.fn.getreg(""), "\n"),
          vim.fn.getregtype(""),
        }
      end

      vim.g.clipboard = {
        name = "OSC 52",
        copy = {
          ["+"] = require("vim.ui.clipboard.osc52").copy("+"),
          ["*"] = require("vim.ui.clipboard.osc52").copy("*"),
        },
        paste = {
          ["+"] = paste,
          ["*"] = paste,
        },
      }
    end
  '';
}
