return {
	{
		"L3MON4D3/LuaSnip",
		event = "InsertEnter",
		dependencies = { "rafamadriz/friendly-snippets" },
		config = function()
			require("luasnip.loaders.from_vscode").lazy_load()
		end,
	},
	{
		"hrsh7th/nvim-cmp",
		event = "InsertEnter",
		dependencies = {
			"hrsh7th/cmp-nvim-lsp",
			"hrsh7th/cmp-buffer",
			"hrsh7th/cmp-path",
			"hrsh7th/cmp-cmdline",
			"saadparwaiz1/cmp_luasnip",
		},
		opts = function()
			local cmp = require("cmp")
			local luasnip = require("luasnip")
			return {
				snippet = {
					expand = function(args)
						luasnip.lsp_expand(args.body)
					end,
				},
				window = {},
				mapping = cmp.mapping.preset.insert({
					["<C-Space>"] = cmp.mapping.complete(),
					["<CR>"] = cmp.mapping.confirm({ select = true }),
					["<Tab>"] = cmp.mapping(function(fallback)
						if cmp.visible() then
							cmp.select_next_item()
						elseif luasnip.expand_or_jumpable() then
							luasnip.expand_or_jump()
						else
							fallback()
						end
					end, { "i", "s" }),
					["<S-Tab>"] = cmp.mapping(function(fallback)
						if cmp.visible() then
							cmp.select_prev_item()
						elseif luasnip.jumpable(-1) then
							luasnip.jump(-1)
						else
							fallback()
						end
					end, { "i", "s" }),
				}),
				sources = cmp.config.sources({
					{ name = "nvim_lsp" },
					{ name = "luasnip" },
					{ name = "path" },
				}, {
					{ name = "buffer" },
				}),
			}
		end,
		config = function(_, opts)
			local cmp = require("cmp")
			local function set_cmp_border_hl()
				local hl = vim.api.nvim_get_hl(0, { name = "DiagnosticWarn", link = false }) or {}
				local yellow = hl.fg or vim.api.nvim_get_hl(0, { name = "WarningMsg", link = false }).fg or "#E6B450"
				pcall(vim.api.nvim_set_hl, 0, "CmpBorder", { fg = yellow, bg = "NONE" })
			end
			set_cmp_border_hl()
			vim.api.nvim_create_autocmd("ColorScheme", {
				group = vim.api.nvim_create_augroup("CmpBorderHL", { clear = true }),
				callback = set_cmp_border_hl,
			})
			opts.window = opts.window or {}

			-- Keep bordered windows and colored border highlight. Use a configurable
			-- global `vim.g.pumwidth` for max width and global `vim.o.pumheight` for height.
			local max_w = math.min(vim.g.pumwidth or 80, math.floor(vim.o.columns * 0.5))
			local doc_max_w = math.min((vim.g.pumwidth and vim.g.pumwidth * 1.2) or 100, math.floor(vim.o.columns * 0.6))
			opts.window.completion = cmp.config.window.bordered({
				border = "rounded",
				winhighlight = "Normal:Pmenu,FloatBorder:CmpBorder,CursorLine:PmenuSel,Search:None",
				max_width = max_w,
				max_height = vim.o.pumheight,
			})
			opts.window.documentation = cmp.config.window.bordered({
				border = "rounded",
				winhighlight = "Normal:Normal,FloatBorder:CmpBorder,CursorLine:PmenuSel,Search:None",
				max_width = doc_max_w,
				max_height = math.max(4, math.floor((vim.o.lines - vim.o.cmdheight) * 0.35)),
			})
			cmp.setup(opts)

			cmp.setup.cmdline({ "/", "?" }, {
				mapping = cmp.mapping.preset.cmdline(),
				sources = { { name = "buffer" } },
			})
			cmp.setup.cmdline(":", {
				mapping = cmp.mapping.preset.cmdline(),
				sources = cmp.config.sources({ { name = "path" } }, { { name = "cmdline" } }),
			})
		end,
	},
}
