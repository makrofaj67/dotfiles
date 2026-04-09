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

vim.cmd([[
  set winblend=0
	highlight FloatBorder guifg=LightGrey guibg=NONE
]])
