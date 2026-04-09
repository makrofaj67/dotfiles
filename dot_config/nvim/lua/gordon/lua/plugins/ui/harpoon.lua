return {
	-- Harpoon V2: Saniyenin onda biri kadar hizla 4-5 dosya arasinda amansizca mekik dokumak
	"ThePrimeagen/harpoon",
	branch = "harpoon2",
	dependencies = { "nvim-lua/plenary.nvim" },
	opts = {
		settings = {
			save_on_toggle = true,
			sync_on_ui_close = true,
		},
	},
	keys = {
		{
			"<leader>a",
			function()
				require("harpoon"):list():add()
			end,
			desc = "Harpoon'a Ekle (Dosyayi Igneler)",
		},
		{
			"<leader>h",
			function()
				local harpoon = require("harpoon")
				harpoon.ui:toggle_quick_menu(harpoon:list())
			end,
			desc = "Harpoon Ana Menusu (Pinlenmis Dosyalar)",
		},
		-- Alt (Meta) tusu ile numaralar arasinda mermi gibi gidisler
		{ "<M-1>", function() require("harpoon"):list():select(1) end, desc = "Harpoon Dosya 1" },
		{ "<M-2>", function() require("harpoon"):list():select(2) end, desc = "Harpoon Dosya 2" },
		{ "<M-3>", function() require("harpoon"):list():select(3) end, desc = "Harpoon Dosya 3" },
		{ "<M-4>", function() require("harpoon"):list():select(4) end, desc = "Harpoon Dosya 4" },
		{ "<M-5>", function() require("harpoon"):list():select(5) end, desc = "Harpoon Dosya 5" },
	},
}
