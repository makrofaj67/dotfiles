return {
	{
		"williamboman/mason.nvim",
		build = ":MasonUpdate",
		cmd = { "Mason", "MasonInstall", "MasonUpdate" },
		opts = {
			ui = {
				icons = {
					package_installed = "✓",
					package_pending = "➜",
					package_uninstalled = "✗",
				},
			},
		},
	},
	{
		"neovim/nvim-lspconfig",
		dependencies = {
			"williamboman/mason.nvim",
			"williamboman/mason-lspconfig.nvim",
			"hrsh7th/cmp-nvim-lsp", -- Kalinti destegi
		},
		event = { "BufReadPre", "BufNewFile" },
		config = function()
			local lspconfig = require("lspconfig")
			local mason_lspconfig = require("mason-lspconfig")

			-- Ide Tarzi Sol Kolon Hata Ikonlari (Gutter Signs)
			local signs = { Error = " ", Warn = " ", Hint = "󰠠 ", Info = " " }
			for type, icon in pairs(signs) do
				local hl = "DiagnosticSign" .. type
				vim.fn.sign_define(hl, { text = icon, texthl = hl, numhl = "" })
			end

			local capabilities = vim.lsp.protocol.make_client_capabilities()
			
			local ok_blink, blink = pcall(require, "blink.cmp")
			if ok_blink then
				capabilities = blink.get_lsp_capabilities(capabilities)
			else
				local ok_cmp, cmp_lsp = pcall(require, "cmp_nvim_lsp")
				if ok_cmp then
					capabilities = cmp_lsp.default_capabilities(capabilities)
				end
			end

			local function on_attach(client, bufnr)
				local nmap = function(keys, func, desc)
					if desc then desc = "LSP: " .. desc end
					vim.keymap.set("n", keys, func, { buffer = bufnr, desc = desc })
				end

				-- Fzf-lua'nin essiz gorselligi ile IDE Tarzi Ziplama 
				nmap("gd", "<cmd>FzfLua lsp_definitions<cr>", "Goto Definition (Fzf)")
				nmap("gr", "<cmd>FzfLua lsp_references<cr>", "References (Fzf)")
				nmap("gD", vim.lsp.buf.declaration, "Goto Declaration")
				nmap("gi", "<cmd>FzfLua lsp_implementations<cr>", "Goto Implementation (Fzf)")
				nmap("K", vim.lsp.buf.hover, "Hover")
				
				-- Snacks/Modern LSP Rename (Tatli ufak popup)
				nmap("<leader>rn", vim.lsp.buf.rename, "Rename")
				
				-- Fzf-lua uzerinden onizlemeli (Diff) Kod Aksiyonu
				nmap("<leader>ca", "<cmd>FzfLua lsp_code_actions<cr>", "Code Action (Fzf)")
				
				nmap("<leader>f", function() vim.lsp.buf.format({ async = true }) end, "Format")

				-- 42 Okulu C/C++ ve Rust Icin Muazzam Inlay Hints (Eger nvim 0.10+ destekliyorsa)
				if client.server_capabilities.inlayHintProvider and vim.lsp.inlay_hint then
					vim.lsp.inlay_hint.enable(true, { bufnr = bufnr })
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
						elseif server == "clangd" then
							local util = require("lspconfig.util")
							opts.root_dir = function(fname)
								return util.root_pattern("Makefile", "configure.ac", "configure.in", "config.h.in", "meson.build", "meson_options.txt", "build.ninja")(fname)
									or util.root_pattern("compile_commands.json", "compile_flags.txt")(fname)
									or util.find_git_ancestor(fname)
							end
							opts.cmd = {
								"clangd",
								"--background-index",
								"--clang-tidy",
								"--header-insertion=iwyu",
								"--completion-style=detailed",
								"--function-arg-placeholders",
								"--fallback-style=llvm",
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
