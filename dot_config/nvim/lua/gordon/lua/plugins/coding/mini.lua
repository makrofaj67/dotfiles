return {
	-- Otomatik parantez/tirnak kapatma
	{
		"echasnovski/mini.pairs",
		event = "VeryLazy",
		opts = {
			modes = { insert = true, command = true, terminal = false },
		},
	},
	-- C++ ve C'ciler icin asiri hizli parantez/quote ekleme, cikarma manipulasyonu
	{
		"echasnovski/mini.surround",
		event = "VeryLazy",
		opts = {
			mappings = {
				add = "sa", -- Kelimenin etrafina ekle (Orn: saiw" kelimeyi tirnak icine alir)
				delete = "sd", -- Kelimenin etrafindakini sil (Orn: sd" tirnaklari curutur)
				replace = "sr", -- Etrafindakini degistir (Orn: sr"' tekli tirnagi cifte cevirir)
				find = "sf", -- Sagindaki sarmalama ogesini bul
				find_left = "sF", -- Solundaki sarmalama ogesini bul
				highlight = "sh", -- Sarmalanan kismi isaretle
			},
		},
	},
}
