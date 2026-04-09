return {
	-- NvChad Base46 port. Standart nvim'e NvChad renklerini asilar.
	"yardnsm/nvim-base46",
	lazy = false,
	priority = 1000,
	opts = {},
	config = function()
		-- Varsayilan acilis temasi.
		vim.cmd.colorscheme("base46-ayu_dark")
		-- Float border gibi bizim Cmp/Soba bagimliliklarimizi her tema 
		-- degistiginde (fzf-lua ile) aktiflestirmesi icin baslatma
		pcall(function() require("core.autocmds") end)
	end,
}
