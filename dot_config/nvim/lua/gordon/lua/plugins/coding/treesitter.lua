return {
	"nvim-treesitter/nvim-treesitter",
	build = ":TSUpdate",
	event = { "BufReadPost", "BufNewFile" },
	dependencies = {
		"nvim-treesitter/nvim-treesitter-textobjects",
	},
	opts = {
		ensure_installed = {
			"c",
			"cpp",
			"lua",
			"vim",
			"vimdoc",
			"query",
			"markdown",
			"markdown_inline",
		},
		highlight = { enable = true, additional_vim_regex_highlighting = false },
		indent = { enable = true },
		incremental_selection = {
			enable = true,
			keymaps = {
				init_selection = "gnn",
				node_incremental = "grn",
				node_decremental = "grm",
				scope_incremental = "grc",
			},
		},
		textobjects = {
			select = {
				enable = true,
				lookahead = true, -- Otomatik olarak asagidaki nesneye ziplar
				keymaps = {
					["af"] = { query = "@function.outer", desc = "Sec: Fonksiyon Disi" },
					["if"] = { query = "@function.inner", desc = "Sec: Fonksiyon Ici" },
					["ac"] = { query = "@class.outer", desc = "Sec: Sinif Disi" },
					["ic"] = { query = "@class.inner", desc = "Sec: Sinif Ici" },
					["aa"] = { query = "@parameter.outer", desc = "Sec: Arguman/Parametre Disi" },
					["ia"] = { query = "@parameter.inner", desc = "Sec: Arguman/Parametre Ici" },
				},
			},
		},
	},
	config = function(_, opts)
		local ok, configs = pcall(require, "nvim-treesitter.configs")
		if ok then
			configs.setup(opts)
		end
	end,
}
