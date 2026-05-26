vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

vim.opt.termguicolors = true
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.scrolloff = 10

vim.opt.tabstop = 4
vim.opt.shiftwidth = 4
vim.opt.softtabstop = 4
vim.opt.expandtab = false
vim.opt.smartindent = true
vim.opt.autoindent = true

vim.opt.signcolumn = "yes"
vim.opt.showmatch = true
vim.opt.completeopt = "menuone,noinsert,noselect"
vim.opt.lazyredraw = true 

vim.opt.pumheight = 10
vim.opt.pumblend = 10
vim.opt.winblend = 0 

vim.opt.showmode = false
vim.opt.pumheight = 10
vim.opt.pumblend = 10
vim.opt.winblend = 0

vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.hlsearch = true
vim.opt.incsearch = true

vim.opt.backup = false
vim.opt.writebackup = false
vim.opt.swapfile = false
vim.opt.autoread = true
vim.opt.autowrite = false
vim.opt.undofile = true

local undodir = "/home/rakman/.local/share/nvim/undo"
if
    vim.fn.isdirectory(undodir) == 0
then
    vim.fn.mkdir(undodir, "p")
end
vim.opt.undodir = undodir

vim.opt.selection = "inclusive"

vim.opt.foldmethod = "expr"
vim.opt.foldexpr = "v:lua.vim.treesitter.foldexpr()"
vim.opt.foldlevel = 99

vim.opt.backspace = "indent,eol,start"

vim.opt.splitbelow = true
vim.opt.splitright = true

vim.opt.wildmenu = true
vim.opt.wildmode = "longest:full,full"
vim.opt.clipboard:append("unnamedplus")

vim.opt.linebreak = true
vim.opt.mouse = "a"
vim.opt.showtabline = 2
vim.opt.cursorlineopt = "both"
vim.opt.cursorline = true
vim.opt.showmode = false
vim.opt.ruler = true
vim.opt.selection = "inclusive"

vim.opt.breakindent = true
vim.opt.confirm = true
