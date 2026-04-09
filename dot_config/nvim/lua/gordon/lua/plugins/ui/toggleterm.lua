return {
	"akinsho/toggleterm.nvim",
	version = "*",
	config = function()
		local ui = vim.api.nvim_list_uis()[1]
		local cols = (ui and ui.width) or vim.o.columns
		local lines = (ui and ui.height) or vim.o.lines
		local width = math.floor(cols * 0.4)
		local height = math.floor(lines * 0.3)
		local row = math.floor(lines * 0.7)
		local col = math.floor(cols * 0.6)

		require("toggleterm").setup({
			size = 20,
			open_mapping = [[<C-s>]],
			hide_numbers = true,
			shade_filetypes = {},
			shade_terminals = true,
			shading_factor = 2,
			start_in_insert = true,
			insert_mappings = true,
			terminal_mappings = true,
			persist_size = true,
			close_on_exit = false,
			shell = vim.o.shell,
			float_opts = {
				border = "curved",
				winblend = 3,
				width = width,
				height = height,
				row = row,
				col = col,
				highlights = {
					border = "Normal",
					background = "Normal",
				},
			},
		})
	end,
}
