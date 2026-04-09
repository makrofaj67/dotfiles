-- lua/ui/whichkey.lua
return {
	"folke/which-key.nvim",
	event = "VeryLazy",
	init = function()
		vim.o.timeout = true
		vim.o.timeoutlen = 300
	end,
	opts = function()
		return {
			plugins = {
				marks = true,
				registers = true,
				spelling = { enabled = true, suggestions = 20 },
				presets = {
					operators = false,
					motions = false,
					text_objects = false,
					windows = true,
					nav = true,
					z = true,
					g = true,
				},
			},
			icons = { breadcrumb = "»", separator = "➜", group = "+" },
			keys = { scroll_down = "<c-d>", scroll_up = "<c-u>" },
			win = {
				border = "rounded",
			},
			layout = {
			},
		}
	end,
}
