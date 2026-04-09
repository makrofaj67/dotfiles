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
			win = {
				-- NvChad CheatSheet'in estetik durusu
				border = "rounded",
				padding = { 1, 2 },
				title = true,
				title_pos = "center",
			},
		}
	end,
	keys = {
		{
			"<leader>?",
			function()
				require("which-key").show({ global = false })
			end,
			desc = "Global Cheatsheet (NvChad stili) Goster",
		},
	},
}
