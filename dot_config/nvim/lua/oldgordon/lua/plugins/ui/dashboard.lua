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
		animate = { enabled = false },
		bigfile = { enabled = false },
		bufdelete = { enabled = false },
		debug = { enabled = false },
		dim = { enabled = false },
		explorer = { enabled = false },
		git = { enabled = false },
		gitbrowse = { enabled = false },
		image = { enabled = false },
		indent = { enabled = true },
		input = { enabled = false },
		keymap = { enabled = false },
		layout = { enabled = false },
		lazygit = { enabled = false },
		notifier = { enabled = false },
		notify = { enabled = false },
		picker = { enabled = false },
		profiler = { enabled = false },
		quickfile = { enabled = false },
		rename = { enabled = false },
		scope = { enabled = false },
		scratch = { enabled = false },
		scroll = { enabled = false },
		statuscolumn = { enabled = false },
		terminal = { enabled = false },
		toggle = { enabled = false },
		util = { enabled = false },
		win = { enabled = false },
		words = { enabled = false },
		zen = { enabled = false },
	},
}
