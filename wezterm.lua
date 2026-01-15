local wezterm = require("wezterm")

local function is_vi_process(pane)
	return pane:get_foreground_process_name():find("n?vim") ~= nil
end

local function conditional_activate_pane(window, pane, pane_direction, vim_direction)
	if is_vi_process(pane) then
		window:perform_action(wezterm.action.SendKey({ key = vim_direction, mods = "ALT" }), pane)
	else
		window:perform_action(wezterm.action.ActivatePaneDirection(pane_direction), pane)
	end
end

wezterm.on("ActivatePaneDirection-right", function(window, pane)
	conditional_activate_pane(window, pane, "Right", "l")
end)
wezterm.on("ActivatePaneDirection-left", function(window, pane)
	conditional_activate_pane(window, pane, "Left", "h")
end)
wezterm.on("ActivatePaneDirection-up", function(window, pane)
	conditional_activate_pane(window, pane, "Up", "k")
end)
wezterm.on("ActivatePaneDirection-down", function(window, pane)
	conditional_activate_pane(window, pane, "Down", "j")
end)

local colors = {
	rosewater = "#F4DBD6",
	flamingo = "#F0C6C6",
	pink = "#F5BDE6",
	mauve = "#C6A0F6",
	red = "#ED8796",
	maroon = "#EE99A0",
	peach = "#F5A97F",
	yellow = "#EED49F",
	green = "#A6DA95",
	teal = "#8BD5CA",
	sky = "#91D7E3",
	sapphire = "#7DC4E4",
	blue = "#8AADF4",
	lavender = "#B7BDF8",

	text = "#CAD3F5",
	subtext1 = "#B8C0E0",
	subtext0 = "#A5ADCB",
	overlay2 = "#8a8a8a",
	overlay1 = "#757575",
	overlay0 = "#606060",
	surface2 = "#4c4c4c",
	surface1 = "#3c3c3c",
	surface0 = "#2c2c2c",

	base = "#1c1c1c",
	mantle = "#161616",
	crust = "#101010",
}

local function get_process(tab)
	local process_icons = {
		["docker"] = {
			{ Foreground = { Color = colors.blue } },
			{ Text = wezterm.nerdfonts.linux_docker },
		},
		["docker-compose"] = {
			{ Foreground = { Color = colors.blue } },
			{ Text = wezterm.nerdfonts.linux_docker },
		},
		["nvim"] = {
			{ Foreground = { Color = colors.green } },
			{ Text = wezterm.nerdfonts.custom_vim },
		},
		["vim"] = {
			{ Foreground = { Color = colors.green } },
			{ Text = wezterm.nerdfonts.dev_vim },
		},
		["node"] = {
			{ Foreground = { Color = colors.green } },
			{ Text = wezterm.nerdfonts.mdi_hexagon },
		},
		["zsh"] = {
			{ Foreground = { Color = colors.peach } },
			{ Text = wezterm.nerdfonts.dev_terminal },
		},
		["bash"] = {
			{ Foreground = { Color = colors.subtext0 } },
			{ Text = wezterm.nerdfonts.cod_terminal_bash },
		},
		["htop"] = {
			{ Foreground = { Color = colors.yellow } },
			{ Text = wezterm.nerdfonts.mdi_chart_donut_variant },
		},
		["cargo"] = {
			{ Foreground = { Color = colors.peach } },
			{ Text = wezterm.nerdfonts.dev_rust },
		},
		["go"] = {
			{ Foreground = { Color = colors.sapphire } },
			{ Text = wezterm.nerdfonts.mdi_language_go },
		},
		["lazydocker"] = {
			{ Foreground = { Color = colors.blue } },
			{ Text = wezterm.nerdfonts.linux_docker },
		},
		["git"] = {
			{ Foreground = { Color = colors.peach } },
			{ Text = wezterm.nerdfonts.dev_git },
		},
		["lazygit"] = {
			{ Foreground = { Color = colors.peach } },
			{ Text = wezterm.nerdfonts.dev_git },
		},
		["lua"] = {
			{ Foreground = { Color = colors.blue } },
			{ Text = wezterm.nerdfonts.seti_lua },
		},
		["wget"] = {
			{ Foreground = { Color = colors.yellow } },
			{ Text = wezterm.nerdfonts.mdi_arrow_down_box },
		},
		["curl"] = {
			{ Foreground = { Color = colors.yellow } },
			{ Text = wezterm.nerdfonts.mdi_flattr },
		},
		["gh"] = {
			{ Foreground = { Color = colors.mauve } },
			{ Text = wezterm.nerdfonts.dev_github_badge },
		},
	}

	local process_name = string.gsub(tab.active_pane.foreground_process_name, "(.*[/\\])(.*)", "%2")

	return wezterm.format(
		process_icons[process_name]
			or { { Foreground = { Color = colors.sky } }, { Text = string.format("[%s]", process_name) } }
	)
end

local function get_current_working_dir(tab)
	local current_dir = tab.active_pane.current_working_dir
	if current_dir == nil then
		return "?"
	end
	if type(current_dir) == "userdata" then
		current_dir = tostring(current_dir)
	end
	local HOME_DIR = string.format("file://%s", os.getenv("HOME"))

	return current_dir == HOME_DIR and "~" or string.format("%s", string.gsub(current_dir, "(.*[/\\])(.*)", "%2"))
end

wezterm.on("format-tab-title", function(tab)
	return wezterm.format({
		{ Attribute = { Intensity = "Half" } },
		{ Text = string.format(" %s: ", tab.tab_index + 1) },
		"ResetAttributes",
		{ Text = get_process(tab) },
		{ Text = " " },
		{ Text = get_current_working_dir(tab) },
		{ Foreground = { Color = colors.base } },
		{ Text = "▕" },
	})
end)

wezterm.on("update-right-status", function(window)
	window:set_right_status(wezterm.format({
		{ Attribute = { Intensity = "Bold" } },
		{ Text = wezterm.strftime(" %A, %d %B %Y %H:%M ") },
	}))
end)

-- Get built-in Catppuccin Mocha scheme and customize it
local mocha = wezterm.color.get_builtin_schemes()["Catppuccin Mocha"]

-- Create custom Catppuccin Espresso scheme with darker base colors
local espresso = {}
for k, v in pairs(mocha) do
	espresso[k] = v
end

-- Override base colors
espresso.background = "#1c1c1c"
espresso.ansi[1] = "#101010"  -- black (crust)
espresso.ansi[2] = "#f38ba8"  -- red (keep original)
espresso.ansi[3] = "#a6e3a1"  -- green (keep original)
espresso.ansi[4] = "#f9e2af"  -- yellow (keep original)
espresso.ansi[5] = "#89b4fa"  -- blue (keep original)
espresso.ansi[6] = "#f5c2e7"  -- magenta (keep original)
espresso.ansi[7] = "#94e2d5"  -- cyan (keep original)
espresso.ansi[8] = "#bac2de"  -- white (keep original)

espresso.brights[1] = "#4c4c4c"  -- bright black (surface2)
espresso.brights[2] = "#f38ba8"  -- bright red (keep original)
espresso.brights[3] = "#a6e3a1"  -- bright green (keep original)
espresso.brights[4] = "#f9e2af"  -- bright yellow (keep original)
espresso.brights[5] = "#89b4fa"  -- bright blue (keep original)
espresso.brights[6] = "#f5c2e7"  -- bright magenta (keep original)
espresso.brights[7] = "#94e2d5"  -- bright cyan (keep original)
espresso.brights[8] = "#8a8a8a"  -- bright white (overlay2)

-- Override selection and cursor colors
espresso.selection_bg = "#2c2c2c"  -- surface0
espresso.selection_fg = "#cdd6f4"  -- text

-- Override tab bar colors
if espresso.tab_bar == nil then
	espresso.tab_bar = {}
end
espresso.tab_bar.background = "#161616"  -- mantle
espresso.tab_bar.inactive_tab = {
	bg_color = "#161616",  -- mantle
	fg_color = "#757575",  -- overlay1
}
espresso.tab_bar.active_tab = {
	bg_color = "#1c1c1c",  -- base
	fg_color = "#cdd6f4",  -- text
}
espresso.tab_bar.new_tab = {
	bg_color = "#161616",  -- mantle
	fg_color = "#757575",  -- overlay1
}

-- Override scrollbar colors
espresso.scrollbar_thumb = "#2c2c2c"  -- surface0

local config = {
	font = wezterm.font("JetbrainsMono Nerd Font"),
	font_size = 12,
	color_schemes = {
		["Catppuccin Espresso"] = espresso,
	},
	color_scheme = "Catppuccin Espresso",
	default_cursor_style = "SteadyBar",
	window_padding = {
		left = 0,
		right = 0,
		top = 0,
		bottom = 0,
	},
	mux_enable_ssh_agent = false,
	window_decorations = "TITLE | RESIZE",
	hide_tab_bar_if_only_one_tab = true,
	detect_password_input = true,
	initial_cols = 140,
	initial_rows = 40,
	use_resize_increments = false,
	use_fancy_tab_bar = false,
	tab_max_width = 20,
	max_fps = 120,
	mouse_bindings = {
		{
			event = { Down = { streak = 1, button = "Left" } },
			mods = "SUPER",
			action = wezterm.action.OpenLinkAtMouseCursor,
		},
	},
	enable_kitty_graphics = true,
	keys = {
		{
			key = "h",
			mods = "CTRL|SHIFT",
			action = wezterm.action.ActivatePaneDirection("Left"),
		},
		{
			key = "j",
			mods = "CTRL|SHIFT",
			action = wezterm.action.ActivatePaneDirection("Down"),
		},
		{
			key = "k",
			mods = "CTRL|SHIFT",
			action = wezterm.action.ActivatePaneDirection("Up"),
		},
		{
			key = "l",
			mods = "CTRL|SHIFT",
			action = wezterm.action.ActivatePaneDirection("Right"),
		},
	},
}

local toggle_terminal = wezterm.plugin.require("https://github.com/zsh-sage/toggle_terminal.wez")
toggle_terminal.apply_to_config(config, {
	direction = "Down",
	size = { Percent = 35 },
	zoom = {
		auto_zoom_invoker_pane = true,
	},
})

return config
