return {
	-- Fareden tamamen kurtaran MUKEMMEL ziplama (Search/Jump) motoru
	"folke/flash.nvim",
	event = "VeryLazy",
	opts = {
		modes = {
			search = { enabled = true },
			char = { enabled = true },
		},
		-- NvChad Estetikleri acisindan highlight ayarlari
		highlight = {
			backdrop = true,
			matches = true,
			priority = 5000,
		},
	},
	keys = {
		{
			"s",
			mode = { "n", "x", "o" },
			function()
				require("flash").jump()
			end,
			desc = "Ekranda Istedigin Yere Zipla (Flash)",
		},
		{
			"S",
			mode = { "n", "x", "o" },
			function()
				require("flash").treesitter()
			end,
			desc = "Etrafi Treesitter Ile Ac/Zipla (Flash)",
		},
		{
			"r",
			mode = "o",
			function()
				require("flash").remote()
			end,
			desc = "Remote Flash",
		},
		{
			"R",
			mode = { "o", "x" },
			function()
				require("flash").treesitter_search()
			end,
			desc = "Treesitter Arama Flash",
		},
	},
}
