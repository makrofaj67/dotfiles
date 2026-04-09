return {
	-- Neovim'in gozle gorulmeyen 'm' tuşuyla edilen isaretlerini satirin (Gutter) en basina, goz onune, renkli ve buyuk bir Font ile yapistirir.
	"chentoast/marks.nvim",
	event = "VeryLazy",
	opts = {
		default_mappings = true,
		exacts = { enabled = true },
		signs = true,
		mappings = {},
	},
}
