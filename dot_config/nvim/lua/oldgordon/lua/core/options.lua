vim.o.linebreak = true
vim.o.mouse = "a"

vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1
vim.o.ignorecase = true
vim.o.smartcase = true

vim.o.splitbelow = true
vim.o.splitright = true

vim.opt.termguicolors = true

vim.o.swapfile = false

vim.o.showtabline = 2

vim.o.completeopt = "menuone,noselect"

-- Limit popup menu height
vim.o.pumheight = 12
-- Configurable popup menu max width (not built-in; expose as global)
-- You can change this in your config, e.g. `vim.g.pumwidth = 60`
vim.g.pumwidth = 80

local o = vim.o
local g = vim.g

o.clipboard = "unnamedplus"
o.cursorlineopt = "both"
o.cursorline = true
o.tabstop = 4
o.shiftwidth = 4
o.softtabstop = 4
o.expandtab = false
o.relativenumber = true
o.number = true
o.ruler = true
o.signcolumn = "yes"
o.foldmethod = "manual"
o.wrap = true

g.user42 = "rakman"
g.mail42 = "rakman@student.42istanbul.com.tr"

o.undofile = true
o.undodir = os.getenv("HOME") .. "/.local/share/nvim/undo"
-- Use modern shada instead of legacy viminfo
-- Store shada in Neovim state dir (usually ~/.local/state/nvim)
vim.opt.shadafile = vim.fn.stdpath("state") .. "/shada/main.shada"

-- GUI font preference (applies to GUI clients like Neovide/Goneovim; harmless in terminal)
local guifonts = {
	"CaskaydiaCove Nerd Font Mono:h12", -- Nerd Fonts v3 mono family
	"CaskaydiaCove Nerd Font:h12",   -- fallback: v3 non-mono
	"Cascadia Code Nerd Font:h12",   -- fallback: older v2 name
}
o.guifont = table.concat(guifonts, ",")

if g.neovide then
	g.neovide_detach_on_quit = "always_detach"
	g.neovide_scale_factor = 1.0
	vim.o.guifont = "CaskaydiaCove Nerd Font Mono:h10"
end

-- vim.cmd("cd /home/luka/Desktop/push_swap/")

vim.cmd([[
  set winblend=0
	highlight FloatBorder guifg=LightGrey guibg=NONE
]])

-- Ensure popup menu and related cmp highlight groups use a fully black background
local function set_pmenu_hls()
	-- Helper: try a list of highlight groups to find an "ayu" orange color
	local function find_theme_color()
		local candidates = {
			"AyuOrange",
			"AyuYellow",
			"base46_ayu_orange",
			"base46_ayu_dark_orange",
			"Orange",
			"WarningMsg",
			"DiagnosticWarn",
			"Identifier",
			"Title",
			"Function",
		}
		for _, name in ipairs(candidates) do
			local ok, hl = pcall(vim.api.nvim_get_hl, 0, { name = name, link = false })
			if ok and hl then
				if hl.bg then
					return hl.bg
				elseif hl.fg then
					return hl.fg
				end
			end
		end
		return nil
	end

	-- Keep this robust: pcall each to avoid errors if a group doesn't exist yet
	-- Pmenu background fully black
	pcall(vim.api.nvim_set_hl, 0, "Pmenu", { bg = "#000000", fg = "#dcdcdc" })

	-- Try to use the theme's orange for the selection if available
	local theme_col = find_theme_color()
	if theme_col then
		-- use theme color as background for selection; use black foreground for contrast
		pcall(vim.api.nvim_set_hl, 0, "PmenuSel", { bg = theme_col, fg = "#000000", bold = true })
		pcall(vim.api.nvim_set_hl, 0, "CmpItemAbbrMatch", { fg = theme_col })
		pcall(vim.api.nvim_set_hl, 0, "CmpItemAbbrMatchFuzzy", { fg = theme_col })
	else
		-- fallback: slightly lighter dark selection
		pcall(vim.api.nvim_set_hl, 0, "PmenuSel", { bg = "#1e1e1e", fg = "#ffffff", bold = true })
	end

	-- Scrollbar/thumb in popup: keep subtle contrast
	pcall(vim.api.nvim_set_hl, 0, "PmenuSbar", { bg = "#0f0f0f" })
	pcall(vim.api.nvim_set_hl, 0, "PmenuThumb", { bg = "#1e1e1e" })

	-- nvim-cmp specific groups
	pcall(vim.api.nvim_set_hl, 0, "CmpItemAbbr", { bg = "#000000" })
	pcall(vim.api.nvim_set_hl, 0, "CmpItemAbbrDeprecated", { bg = "#000000", fg = "#6b6b6b", strikethrough = true })
	pcall(vim.api.nvim_set_hl, 0, "CmpItemKind", { bg = "#000000" })
	pcall(vim.api.nvim_set_hl, 0, "CmpItemMenu", { bg = "#000000", fg = "#808080" })
end

set_pmenu_hls()

vim.api.nvim_create_autocmd("ColorScheme", {
		group = vim.api.nvim_create_augroup("PmenuHL", { clear = true }),
		callback = set_pmenu_hls,
})

local border = {
	{ "╭", "FloatBorder" },
	{ "─", "FloatBorder" },
	{ "╮", "FloatBorder" },
	{ "│", "FloatBorder" },
	{ "╯", "FloatBorder" },
	{ "─", "FloatBorder" },
	{ "╰", "FloatBorder" },
	{ "│", "FloatBorder" },
}

local orig_util_open_floating_preview = vim.lsp.util.open_floating_preview
function vim.lsp.util.open_floating_preview(contents, syntax, opts, ...)
	opts = opts or {}
	opts.border = opts.border or border
	return orig_util_open_floating_preview(contents, syntax, opts, ...)
end

vim.api.nvim_create_user_command("SilCCom", function()
	local start_line = 1
	local end_line = vim.fn.line("$")
	-- Orijinal satırları oku
	local original_lines = vim.api.nvim_buf_get_lines(0, start_line - 1, end_line, false)
	local result_lines = {}
	local in_multiline_comment = false

	for _, line in ipairs(original_lines) do
		local original = line
		-- Çok satırlı yorumları işaretle
		if in_multiline_comment then
			if line:find("*/") then
				line = line:gsub(".-%*/", "")
				in_multiline_comment = false
			else
				line = "" -- yorumun içindeyse, tamamen sil
			end
		end

		-- Yeni çok satırlı yorum başladıysa
		if not in_multiline_comment and line:find("/%*") then
			in_multiline_comment = not line:find("%*/")
			line = line:gsub("/%*.-%*/", ""):gsub("/%*.*", "")
		end

		-- Tek satır yorumları sil
		line = line:gsub("//.*", "")

		-- Satır sadece yorum içeriyorsa ve orijinali boş değilse, atla
		if line:match("^%s*$") and not original:match("^%s*$") then
			-- sadece yorumdan oluşuyordu, atlıyoruz
		else
			table.insert(result_lines, line)
		end
	end

	-- Sonuçları buffer'a yaz
	vim.api.nvim_buf_set_lines(0, 0, -1, false, result_lines)
end, {})
