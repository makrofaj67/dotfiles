return {
	{
		"zbirenbaum/copilot.lua",
		cmd = "Copilot",
		event = "InsertEnter",
		opts = {
			suggestion = {
				enabled = true,
				auto_trigger = true,
				debounce = 75,
				keymap = {
					accept = "<M-CR>",
					next = "<M-]>",
					prev = "<M-[>",
					dismiss = "<C-]>",
				},
			},
			panel = { enabled = false },
		},
	},
	{
		"CopilotC-Nvim/CopilotChat.nvim",
		dependencies = {
			{ "zbirenbaum/copilot.lua" },
			{ "nvim-lua/plenary.nvim" },
		},
		build = "make tiktoken",
		opts = {
			show_help = "yes",
			window = {
				layout = "float",
				width = 0.8,
				height = 0.8,
				border = "rounded",
			},
		},
		keys = {
			{
				"<leader>cc",
				"<cmd>CopilotChatToggle<cr>",
				desc = "CopilotChat - Aç/Kapat",
			},
			{
				"<leader>cq",
				function()
					local input = vim.fn.input("Copilot'a Sor: ")
					if input ~= "" then
						require("CopilotChat").ask(input, { selection = require("CopilotChat.select").buffer })
					end
				end,
				desc = "CopilotChat - Hızlı Soru",
			},
		},
	},
}
