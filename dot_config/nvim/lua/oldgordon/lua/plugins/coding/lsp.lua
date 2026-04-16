return {
	{
		"williamboman/mason.nvim",
		build = ":MasonUpdate",
		cmd = { "Mason", "MasonInstall", "MasonUpdate" },
		opts = {},
	},
	{
		"WhoIsSethDaniel/mason-tool-installer.nvim",
		dependencies = { "williamboman/mason.nvim" },
		event = "VeryLazy",
		opts = {
			ensure_installed = {
				"clangd",
				"lua_ls",
				"stylua",
				"clang-format",
				"luacheck",
				"cpplint",
			},
			auto_update = false,
			run_on_start = true,
			start_delay = 100,
			debounce_hours = 12,
		},
	},
	{
		"neovim/nvim-lspconfig",
		dependencies = {
			"williamboman/mason.nvim",
			"williamboman/mason-lspconfig.nvim",
			"ray-x/lsp_signature.nvim",
			"hrsh7th/cmp-nvim-lsp",
		},
		event = { "BufReadPre", "BufNewFile" },
		config = function()
			local lspconfig = require("lspconfig")
			local mason_lspconfig = require("mason-lspconfig")

			local capabilities = vim.lsp.protocol.make_client_capabilities()
			local ok_cmp, cmp_lsp = pcall(require, "cmp_nvim_lsp")
			if ok_cmp then
				capabilities = cmp_lsp.default_capabilities(capabilities)
			end

			local function on_attach(client, bufnr)
				local nmap = function(keys, func, desc)
					if desc then desc = "LSP: " .. desc end
					vim.keymap.set("n", keys, func, { buffer = bufnr, desc = desc })
				end

				nmap("gd", vim.lsp.buf.definition, "Goto Definition")
				nmap("gr", vim.lsp.buf.references, "References")
				nmap("gD", vim.lsp.buf.declaration, "Goto Declaration")
				nmap("gi", vim.lsp.buf.implementation, "Goto Implementation")
				nmap("K", vim.lsp.buf.hover, "Hover")
				nmap("<leader>rn", vim.lsp.buf.rename, "Rename")
				nmap("<leader>ca", vim.lsp.buf.code_action, "Code Action")
				nmap("<leader>f", function() vim.lsp.buf.format({ async = true }) end, "Format")

				local ok_sig, sig = pcall(require, "lsp_signature")
				if ok_sig then
					sig.on_attach({ bind = true, hint_enable = false }, bufnr)
				end
			end

			mason_lspconfig.setup({
				ensure_installed = { "clangd", "lua_ls" },
				automatic_installation = true,
				handlers = {
					function(server)
						local opts = { on_attach = on_attach, capabilities = capabilities }
						if server == "lua_ls" then
							opts.settings = {
								Lua = {
									diagnostics = { globals = { "vim" } },
									workspace = { checkThirdParty = false },
									telemetry = { enable = false },
								},
							}
						end
						lspconfig[server].setup(opts)
					end,
				},
			})
		end,
	},
	{ "williamboman/mason-lspconfig.nvim", lazy = true },
}
