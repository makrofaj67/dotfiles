return {
	"romgrk/barbar.nvim",
	dependencies = {
		"nvim-tree/nvim-web-devicons",
		"moll/vim-bbye",
	},
	init = function()
		vim.g.barbar_auto_setup = false
	end,
	config = function()
		local function setup_barbar_highlights()
			local colors = {
				bg = vim.api.nvim_get_hl(0, { name = "Normal" }).bg,
				fg = vim.api.nvim_get_hl(0, { name = "Normal" }).fg,
				bg_dark = vim.api.nvim_get_hl(0, { name = "NormalFloat" }).bg,
				fg_bright = vim.api.nvim_get_hl(0, { name = "Special" }).fg,
				yellow = vim.api.nvim_get_hl(0, { name = "DiagnosticWarn" }).fg,
				accent = vim.api.nvim_get_hl(0, { name = "Function" }).fg,
				fg_dark = "#c0c0c0", -- Sizin özel ayarınız
			}

			local function safe_set_hl(name, opts)
				pcall(vim.api.nvim_set_hl, 0, name, opts)
			end

			safe_set_hl("BufferCurrent", { fg = colors.fg_bright, bg = colors.bg, bold = true })
			safe_set_hl("BufferCurrentMod", { fg = colors.yellow, bg = colors.bg, bold = true })
			safe_set_hl("BufferCurrentSign", { fg = colors.accent, bg = colors.bg })
			safe_set_hl("BufferCurrentIcon", { fg = colors.fg_bright, bg = colors.bg })

			safe_set_hl("BufferVisible", { fg = colors.fg_dark, bg = colors.bg_dark })
			safe_set_hl("BufferVisibleMod", { fg = colors.yellow, bg = colors.bg_dark })
			safe_set_hl("BufferVisibleSign", { fg = colors.fg_dark, bg = colors.bg_dark })
			safe_set_hl("BufferVisibleIcon", { fg = colors.fg_dark, bg = colors.bg_dark })

			safe_set_hl("BufferInactive", { fg = colors.fg_dark, bg = colors.bg_dark })
			safe_set_hl("BufferInactiveMod", { fg = colors.yellow, bg = colors.bg_dark })
			safe_set_hl("BufferInactiveSign", { fg = colors.fg_dark, bg = colors.bg_dark })
			safe_set_hl("BufferInactiveIcon", { fg = colors.fg_dark, bg = colors.bg_dark })

			safe_set_hl("BufferTabpageFill", { fg = colors.fg, bg = colors.bg_dark })
		end

		require("barbar").setup({
			animation = false,
			auto_hide = false,
			tabpages = true,
			clickable = true,
			exclude_ft = { "neo-tree", "Trouble" },
			icons = {
				buffer_index = false,
				buffer_number = false,
				button = "λ",
				preset = "default",
				diagnostics = {
					[vim.diagnostic.severity.ERROR] = { enabled = false },
					[vim.diagnostic.severity.WARN] = { enabled = false },
					[vim.diagnostic.severity.INFO] = { enabled = false },
					[vim.diagnostic.severity.HINT] = { enabled = false },
				},
				gitsigns = {
					added = { enabled = false },
					changed = { enabled = false },
					deleted = { enabled = false },
				},
				filetype = {
					custom_colors = false,
					enabled = true,
				},
				separator = { left = "┃", right = "" },
				separator_at_end = true,
			},
			sidebar_filetypes = {
				["neo-tree"] = { text = "blλack mesa", align = "center" },
			},
			focus_on_close = "previous",
			hide = { inactive = false },
			highlight_visible = true,
			highlight_alternate = false,
			highlight_inactive_file_icons = false,
			no_name_title = "New Buffer",
		})
		local map = vim.api.nvim_set_keymap
		local opts = { noremap = true, silent = true }
		map("n", "<A-,>", "<Cmd>BufferPrevious<CR>", opts)
		map("n", "<A-.>", "<Cmd>BufferNext<CR>", opts)

		vim.api.nvim_create_augroup("BarbarConfig", { clear = true })
		vim.api.nvim_create_autocmd("ColorScheme", {
			group = "BarbarConfig",
			callback = setup_barbar_highlights,
		})
		setup_barbar_highlights()
	end,
}
