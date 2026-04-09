return
{
	"mawkler/modicator.nvim",
	lazy = false,
	priority = 900,
	opts = {
		show_warnings = false,
		highlights = {
			defaults = {
				bold = false,
				italic = false,
			},
			use_cursorline_background = false,
		},
		integration = {
			lualine = {
				enabled = true,
				highlight = "bg",
			},
		},
	},
}
