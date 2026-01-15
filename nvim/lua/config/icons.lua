-- Minimal icon set (replacement for LazyVim.config.icons).
-- Keep this small and dependency-free.
return {
  diagnostics = {
    Error = " ",
    Warn = " ",
    Info = " ",
    Hint = " ",
  },
  git = {
    added = " ",
    modified = " ",
    removed = " ",
  },
  -- LSP completion kinds (for blink.cmp / completion menus).
  kinds = {
    Text = "󰉿 ",
    Method = "󰆧 ",
    Function = "󰊕 ",
    Constructor = " ",
    Field = "󰜢 ",
    Variable = "󰀫 ",
    Class = "󰠱 ",
    Interface = " ",
    Module = " ",
    Property = "󰜢 ",
    Unit = "󰑭 ",
    Value = "󰎠 ",
    Enum = " ",
    Keyword = "󰌋 ",
    Snippet = " ",
    Color = "󰏘 ",
    File = "󰈙 ",
    Reference = "󰈇 ",
    Folder = "󰉋 ",
    EnumMember = " ",
    Constant = "󰏿 ",
    Struct = "󰙅 ",
    Event = " ",
    Operator = "󰆕 ",
    TypeParameter = "󰊄 ",
  },
}

