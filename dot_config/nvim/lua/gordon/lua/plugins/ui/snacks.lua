return {
	"folke/snacks.nvim",
	priority = 1000,
	lazy = false,
	opts = {
		dashboard = {
			enabled = true,
			preset = {
header = [[
▀█████████▄   ▄█          ▄████████  ▄████████    ▄█   ▄█▄ 
  ███    ███ ███         ███    ███ ███    ███   ███ ▄███▀ 
  ███    ███ ███         ███    ███ ███    █▀    ███▐██▀   
 ▄███▄▄▄██▀  ███         ███    ███ ███         ▄█████▀    
▀▀███▀▀▀██▄  ███       ▀███████████ ███        ▀▀█████▄    
  ███    ██▄ ███         ███    ███ ███    █▄    ███▐██▄   
  ███    ███ ███▌    ▄   ███    ███ ███    ███   ███ ▀███▄ 
▄█████████▀  █████▄▄██   ███    █▀  ████████▀    ███   ▀█▀ 
             ▀                                   ▀         
   ▄▄▄▄███▄▄▄▄      ▄████████    ▄████████    ▄████████    
 ▄██▀▀▀███▀▀▀██▄   ███    ███   ███    ███   ███    ███    
 ███   ███   ███   ███    █▀    ███    █▀    ███    ███    
 ███   ███   ███  ▄███▄▄▄       ███          ███    ███    
 ███   ███   ███ ▀▀███▀▀▀     ▀███████████ ▀███████████    
 ███   ███   ███   ███    █▄           ███   ███    ███    
 ███   ███   ███   ███    ███    ▄█    ███   ███    ███    
  ▀█   ███   █▀    ██████████  ▄████████▀    ███    █▀     ]],
				keys = {
					{ icon = " ", key = "f", desc = "Find Files", action = ":lua Snacks.dashboard.pick('files')" },
					{ icon = " ", key = "n", desc = "New File", action = ":ene | startinsert" },
					{ icon = " ", key = "g", desc = "Search", action = ":lua Snacks.dashboard.pick('live_grep')" },
					{ icon = " ", key = "r", desc = "Last Files", action = ":lua Snacks.dashboard.pick('oldfiles')" },
					{ icon = " ", key = "c", desc = "Settings", action = ":lua Snacks.dashboard.pick('files', {cwd = vim.fn.stdpath('config')})" },
					{ icon = "󰒲 ", key = "l", desc = "Lazy Settings", action = ":Lazy" },
					{ icon = " ", key = "q", desc = "Exit", action = ":qa" },
				},
			},
		},
		input = { enabled = true },
		notifier = { enabled = true, timeout = 3000 },
		indent = { enabled = true },
	},
	keys = {
		{ "<leader>n", function() Snacks.notifier.show_history() end, desc = "Bildirim Gecmisini Goster" },
		{ "<leader>d", function() Snacks.dashboard.open() end, desc = "Soba (Dashboard) Ekrani Ac" },
	}
}
