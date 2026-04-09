return {
	-- Kodda duzeltilebilir bir hata varsa CLion/VSCode'daki gibi ekrana 💡 (ampul) cikarir
	{
		"kosayoda/nvim-lightbulb",
		event = "LspAttach",
		opts = {
			autocmd = { enabled = true },
			sign = { enabled = true, text = "💡" },
		},
	},
	-- Cildirtici renksiz standart Neovim hatalari yerine inanilmaz estetik arka plani renkli modern okunabilir Ui
	{
		"rachartier/tiny-inline-diagnostic.nvim",
		event = "VeryLazy",
		priority = 1000,
		config = function()
			require("tiny-inline-diagnostic").setup()
			-- Standart neovim sanal metinlerini kapat ki cirkin eski tasarimla yeni tasarim birbirine girmesin
			vim.diagnostic.config({ virtual_text = false })
		end,
	},
}
