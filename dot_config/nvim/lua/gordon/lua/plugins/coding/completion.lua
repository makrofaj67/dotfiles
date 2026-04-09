return {
	-- Cmp'yi kaldirip yerine isik hizinda, gecikmesiz calisan yeni nesil Blink'i kuruyoruz
	{
		"saghen/blink.cmp",
		lazy = false, -- Blink kesinlikle onceden ayarlanmali
		dependencies = {
			"rafamadriz/friendly-snippets",
			{
				"L3MON4D3/LuaSnip",
				version = "v2.*",
				config = function()
					pcall(function() require("luasnip.loaders.from_vscode").lazy_load() end)
				end
			},
		},
		version = "*",
		opts = {
			keymap = {
				preset = "super-tab",       -- NvChad sevdigi sekilde Tab ile gez, Enter ile onayla
				["<CR>"] = { "accept", "fallback" },
			},
			appearance = {
				use_nvim_cmp_as_default = false,
				nerd_font_variant = "mono",
			},
			signature = {
				enabled = true,
				window = { border = "rounded", winhighlight = "Normal:Pmenu,FloatBorder:CmpBorder" },
			},
			completion = {
				accept = { auto_brackets = { enabled = true } },
				menu = { 
					draw = {
						treesitter = { "lsp" },
					},
					border = "rounded",
					-- Nvchad stili seffaf vurgu tablolari, FloatBorder CmpBorder'dan (Sari) beslenir.
					winhighlight = "Normal:Pmenu,FloatBorder:CmpBorder,CursorLine:PmenuSel,Search:None",
				},
				documentation = {
					auto_show = true,
					auto_show_delay_ms = 200,
					window = { 
						border = "rounded",
						winhighlight = "Normal:Normal,FloatBorder:CmpBorder",
					}
				},
			},
			snippets = { preset = "luasnip" },
			sources = {
				default = { "lsp", "path", "snippets", "buffer" },
			},
		},
	},
}
