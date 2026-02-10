local wezterm = require("wezterm")

local espresso_tabline = {
  normal_mode = {
    a = { fg = "#1c1c1c", bg = "#89b4fa" },
    b = { fg = "#89b4fa", bg = "#2c2c2c" },
    c = { fg = "#cdd6f4", bg = "#161616" },
  },
  copy_mode = {
    a = { fg = "#1c1c1c", bg = "#f9e2af" },
    b = { fg = "#f9e2af", bg = "#2c2c2c" },
    c = { fg = "#cdd6f4", bg = "#161616" },
  },
  search_mode = {
    a = { fg = "#1c1c1c", bg = "#a6e3a1" },
    b = { fg = "#a6e3a1", bg = "#2c2c2c" },
    c = { fg = "#cdd6f4", bg = "#161616" },
  },
  window_mode = {
    a = { fg = "#1c1c1c", bg = "#cba6f7" },
    b = { fg = "#cba6f7", bg = "#2c2c2c" },
    c = { fg = "#cdd6f4", bg = "#161616" },
  },
  tab = {
    active = { fg = "#89b4fa", bg = "#2c2c2c" },
    inactive = { fg = "#cdd6f4", bg = "#161616" },
    inactive_hover = { fg = "#f5c2e7", bg = "#2c2c2c" },
  },
}

wezterm.plugin.require("https://github.com/michaelbrusegard/tabline.wez")
    .setup({
      options = {
        icons_enabled = true,
        theme = "Catppuccin Mocha",
        tabs_enabled = true,
        theme_overrides = espresso_tabline,
        section_separators = {
          left = "",
          right = "",
        },
        component_separators = {
          left = "",
          right = "",
        },
        tab_separators = {
          left = "",
          right = "",
        },
      },
      sections = {
        tabline_a = {},
        tabline_b = { 'workspace' },
        tabline_c = { ' ' },
        tab_active = {
          'index',
          { 'process', padding = { left = 0, right = 1 } },
          '',
          { 'cwd',     padding = { left = 1, right = 1 } },
        },
        tab_inactive = {
          'index',
          { 'process', padding = { left = 0, right = 1 } },
          '',
          { 'cwd',     padding = { left = 1, right = 1 } },
        },
        tabline_x = { 'ram', 'cpu' },
        tabline_y = { 'datetime', 'battery' },
        tabline_z = { 'domain' },
      },
      extensions = {
        'resurrect',
        'smart_workspace_switcher',
        'quick_domains',
        'presentation',
      },
    })

-- Get built-in Catppuccin Mocha scheme and customize it
local mocha = wezterm.color.get_builtin_schemes()["Catppuccin Mocha"]

-- Create custom Catppuccin Espresso scheme with darker base colors
local espresso = {}
for k, v in pairs(mocha) do
  espresso[k] = v
end

-- Override base colors
espresso.background = "#1c1c1c"
espresso.ansi[1] = "#101010"    -- black (crust)
espresso.ansi[2] = "#f38ba8"    -- red (keep original)
espresso.ansi[3] = "#a6e3a1"    -- green (keep original)
espresso.ansi[4] = "#f9e2af"    -- yellow (keep original)
espresso.ansi[5] = "#89b4fa"    -- blue (keep original)
espresso.ansi[6] = "#f5c2e7"    -- magenta (keep original)
espresso.ansi[7] = "#94e2d5"    -- cyan (keep original)
espresso.ansi[8] = "#bac2de"    -- white (keep original)

espresso.brights[1] = "#4c4c4c" -- bright black (surface2)
espresso.brights[2] = "#f38ba8" -- bright red (keep original)
espresso.brights[3] = "#a6e3a1" -- bright green (keep original)
espresso.brights[4] = "#f9e2af" -- bright yellow (keep original)
espresso.brights[5] = "#89b4fa" -- bright blue (keep original)
espresso.brights[6] = "#f5c2e7" -- bright magenta (keep original)
espresso.brights[7] = "#94e2d5" -- bright cyan (keep original)
espresso.brights[8] = "#8a8a8a" -- bright white (overlay2)

-- Override selection and cursor colors
espresso.selection_bg = "#2c2c2c" -- surface0
espresso.selection_fg = "#cdd6f4" -- text

-- Override tab bar colors
if espresso.tab_bar == nil then
  espresso.tab_bar = {}
end
espresso.tab_bar.background = "#161616" -- mantle
espresso.tab_bar.inactive_tab = {
  bg_color = "#161616",                 -- mantle
  fg_color = "#757575",                 -- overlay1
}
espresso.tab_bar.active_tab = {
  bg_color = "#1c1c1c", -- base
  fg_color = "#cdd6f4", -- text
}
espresso.tab_bar.new_tab = {
  bg_color = "#161616", -- mantle
  fg_color = "#757575", -- overlay1
}

-- Override scrollbar colors
espresso.scrollbar_thumb = "#2c2c2c" -- surface0

local config = {
  animation_fps = 60,
  font = wezterm.font_with_fallback {
    'JetBrains Mono',
    { family = 'Symbols Nerd Font', scale = 1, style = "Normal" },
  },
  font_size = 12,
  line_height = 1,
  color_schemes = {
    ["Catppuccin Espresso"] = espresso,
  },
  color_scheme = "Catppuccin Espresso",
  command_palette_bg_color = "#2c2c2c",
  command_palette_fg_color = "#cdd6f4",
  command_palette_font = wezterm.font("JetbrainsMono Nerd Font"),
  command_palette_font_size = 12,
  leader = { key = "z", mods = "CTRL" },
  default_cursor_style = "SteadyBar",
  window_padding = {
    left = 0,
    right = 0,
    top = 0,
    bottom = 0,
  },
  mux_enable_ssh_agent = false,
  window_decorations = "RESIZE",
  detect_password_input = true,
  initial_cols = 140,
  initial_rows = 40,
  use_resize_increments = true,
  use_fancy_tab_bar = false,
  tab_max_width = 32,
  max_fps = 120,
  mouse_bindings = {
    {
      event = { Down = { streak = 1, button = "Left" } },
      mods = "SUPER",
      action = wezterm.action.OpenLinkAtMouseCursor,
    },
  },
  enable_kitty_graphics = true,
  enable_kitty_keyboard = true,
  unix_domains = {
    { name = "unix" }
  },
  term = "wezterm",
}

wezterm.plugin.require("https://github.com/sei40kr/wez-tmux").apply_to_config(config, {})

wezterm.plugin.require("https://github.com/sei40kr/wez-pain-control").apply_to_config(config, {})

return config
