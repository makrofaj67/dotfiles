return {
	"folke/snacks.nvim",
	priority = 1000,
	lazy = false,
	opts = {
		-- Soba (Acilis Ekrani) - Resimdeki gibi koseleri kapali estetik izole
		dashboard = {
			enabled = true,
			preset = {
				header = [[
   _______  _______  _______  ______   _______  _______ 
  (  ____ \(  ___  )(  ____ )(  __  \ (  ___  )(       )
  | (    \/| (   ) || (    )|| (  \  )| (   ) || () () |
  | |      | |   | || (____)|| |   ) || |   | || || || |
  | | ____ | |   | ||     __)| |   | || |   | || |(_)| |
  | | \_  )| |   | || (\ (   | |   ) || |   | || |   | |
  | (___) || (___) || ) \ \__| (__/  )| (___) || )   ( |
  (_______)(_______)|/   \__/(______/ (_______)|/     \|
                                          
G O R D O N   A R C H I T E C T U R E
				]],
				keys = {
					{ icon = " ", key = "f", desc = "Dosya Bul", action = ":lua Snacks.dashboard.pick('files')" },
					{ icon = " ", key = "n", desc = "Yeni Dosya", action = ":ene | startinsert" },
					{ icon = " ", key = "g", desc = "Arama Yap", action = ":lua Snacks.dashboard.pick('live_grep')" },
					{ icon = " ", key = "r", desc = "Son Dosyalar", action = ":lua Snacks.dashboard.pick('oldfiles')" },
					{ icon = " ", key = "c", desc = "Ayarlar", action = ":lua Snacks.dashboard.pick('files', {cwd = vim.fn.stdpath('config')})" },
					{ icon = "󰒲 ", key = "l", desc = "Lazy Yoneticisi", action = ":Lazy" },
					{ icon = " ", key = "q", desc = "Cikis", action = ":qa" },
				},
			},
		},
		-- Guzel Variable Renamer Kutucugu (Cok kucuk ve estetik lsp rename popupi ayni nvchad gibi)
		input = { enabled = true },
		-- Sag alt kose saglam bildirimler (notify spami onler)
		notifier = { enabled = true, timeout = 3000 },
	},
	keys = {
		{ "<leader>n", function() Snacks.notifier.show_history() end, desc = "Bildirim Gecmisini Goster" },
		{ "<leader>d", function() Snacks.dashboard.open() end, desc = "Soba (Dashboard) Ekrani Ac" },
	}
}
