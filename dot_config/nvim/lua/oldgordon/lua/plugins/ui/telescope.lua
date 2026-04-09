-- lua/ui/telescope.lua
return {
	"nvim-telescope/telescope.nvim",
	tag = "0.1.6",
	dependencies = {
		"nvim-lua/plenary.nvim",
		{
			"nvim-telescope/telescope-fzf-native.nvim",
			build = "make",
			cond = function()
				return vim.fn.executable("make") == 1
			end,
		},
		{ "nvim-telescope/telescope-ui-select.nvim" },
	},
	keys = {
		{ "<leader>ff",       "<cmd>Telescope find_files<cr>",  desc = "Dosyalarda Ara" },
		{ "<leader>fg",       "<cmd>Telescope live_grep<cr>",   desc = "Metin Ara (Grep)" },
		{ "<leader>fb",       "<cmd>Telescope buffers<cr>",     desc = "Bufferlarda Ara" },
		{ "<leader>fh",       "<cmd>Telescope help_tags<cr>",   desc = "Yardımda Ara" },
		{ "<leader>sh",       "<cmd>Telescope help_tags<cr>",   desc = "[S]earch [H]elp" },
		{ "<leader>sk",       "<cmd>Telescope keymaps<cr>",     desc = "[S]earch [K]eymaps" },
		{ "<leader>sf",       "<cmd>Telescope find_files<cr>",  desc = "[S]earch [F]iles" },
		{ "<leader>ss",       "<cmd>Telescope builtin<cr>",     desc = "[S]earch [S]elect Telescope" },
		{ "<leader>sw",       "<cmd>Telescope grep_string<cr>", desc = "[S]earch current [W]ord" },
		{ "<leader>sg",       "<cmd>Telescope live_grep<cr>",   desc = "[S]earch by [G]rep" },
		{ "<leader>sd",       "<cmd>Telescope diagnostics<cr>", desc = "[S]earch [D]iagnostics" },
		{ "<leader>sr",       "<cmd>Telescope resume<cr>",      desc = "[S]earch [R]esume" },
		{ "<leader>s.",       "<cmd>Telescope oldfiles<cr>",    desc = '[S]earch Recent Files ("." for repeat)' },
		{ "<leader><leader>", "<cmd>Telescope buffers<cr>",     desc = "[ ] Find existing buffers" },
		{
			"<leader>/",
			function()
				require("telescope.builtin").current_buffer_fuzzy_find(require("telescope.themes").get_dropdown({
					winblend = 10,
					previewer = false,
				}))
			end,
			desc = "[/] Fuzzily search in current buffer",
		},
		{
			"<leader>sn",
			function()
				require("telescope.builtin").find_files({ cwd = vim.fn.stdpath("config") })
			end,
			desc = "[S]earch [N]eovim files",
		},
	},
	opts = {
		defaults = {
			layout_strategy = "horizontal",
			layout_config = {
				horizontal = { prompt_position = "top", preview_width = 0.55 },
			},
			sorting_strategy = "ascending",
			winblend = 10,
		},
		pickers = {
		},
		extensions = {
			fzf = {
				fuzzy = true,
				override_generic_sorter = true,
				override_file_sorter = true,
				case_mode = "smart_case",
			},
		},
	},
	config = function(_, opts)
		local telescope = require("telescope")
		telescope.setup(opts)
		pcall(telescope.load_extension, "fzf")
		pcall(telescope.load_extension, "ui-select")
	end,
}
