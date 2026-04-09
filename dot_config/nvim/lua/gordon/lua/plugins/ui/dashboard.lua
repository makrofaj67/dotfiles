return {
	"folke/snacks.nvim",
	lazy = false,
	priority = 1000,
	opts = {
		dashboard = {
			width = 60,
			row = nil,
			col = nil,
			pane_gap = 4,
			autokeys = "1234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ",
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
			},
			sections = {
				{ section = "header" },
				{ icon = " ", title = "Keymaps", section = "keys", indent = 2, padding = 1 },
				{ icon = " ", title = "Recent Files", section = "recent_files", indent = 2, padding = 1 },
				{ icon = " ", title = "Projects", section = "projects", indent = 2, padding = 1 },
				{ section = "startup" },
			},
		},
	},
}
