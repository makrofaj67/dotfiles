return {
	base46 = {
		theme = "ayu_dark",
		theme_toggle = { "ayu_dark", "one_light" },
		hl_override = {},
		hl_add = {},
		integrations = {},
		transparency = false,
	},
	ui = {
		cmp = {
			icons_left = false,
			style = "default",
			format_colors = {
				tailwind = false,
				icon = "󱓻",
			},
		},
		telescope = { style = "borderless" }, 
		dev = {
			test = false,
			hot_reload = false,
		},
		statusline = {
			theme = "default",
			separator_style = "default",
			overriden_modules = nil,
		},
		tabufline = {
			show_numbers = false,
			enabled = false,
		},
		nvdash = {
			load_on_startup = false,
		},
	},
}
