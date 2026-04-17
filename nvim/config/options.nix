{
  globals = {
    mapleader = " ";
    neovide_input_macos_option_key_is_meta = "only_left";
    neovide_scroll_animation_length = 0.1;
    neovide_position_animation_length = 0.1;
    neovide_cursor_animation_length = 0.1;
    neovide_show_border = false;
    neovide_cursor_vfx_mode = "";
  };

  opts = {
    autoread = true;
    autowrite = true;
    clipboard.__raw = ''vim.env.SSH_CONNECTION and "" or "unnamedplus"'';
    completeopt = "menu,menuone,noselect";
    conceallevel = 0;
    confirm = true;
    cursorline = true;
    expandtab = true;
    fillchars = "foldopen: ,foldclose: ,fold: ,foldsep: ,diff:╱,eob: ";
    foldlevel = 99;
    foldlevelstart = 99;
    foldmethod = "indent";
    formatoptions = "jcroqlnt";
    grepformat = "%f:%l:%c:%m";
    grepprg = "rg --vimgrep";
    ignorecase = true;
    inccommand = "nosplit";
    jumpoptions = "view";
    laststatus = 3;
    showtabline = 1;
    linebreak = true;
    list = true;
    mouse = "a";
    number = true;
    pumblend = 10;
    pumheight = 10;
    relativenumber = false;
    ruler = false;
    scrolloff = 4;
    sessionoptions = [
      "buffers"
      "curdir"
      "tabpages"
      "winsize"
      "help"
      "globals"
      "skiprtp"
      "folds"
    ];
    shiftround = true;
    shiftwidth = 2;
    showmode = false;
    sidescrolloff = 8;
    signcolumn = "yes";
    smartcase = true;
    smartindent = true;
    smoothscroll = true;
    spelllang = [ "en" ];
    spell = false;
    splitbelow = true;
    splitkeep = "screen";
    splitright = true;
    tabstop = 2;
    termguicolors = true;
    timeoutlen = 300;
    undofile = true;
    undolevels = 10000;
    updatetime = 200;
    virtualedit = "block";
    wildmode = "longest:full,full";
    winminwidth = 5;
    wrap = false;
    breakindent = true;
    breakindentopt = "shift:4";
  };

  dependencies = {
    fd.enable = true;
    ripgrep.enable = true;
    tree-sitter.enable = true;
  };
}
