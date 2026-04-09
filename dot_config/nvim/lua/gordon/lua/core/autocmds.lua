-- Pmenu renkleri ve UI tabanli autocmd/fonksiyonlar

-- Pencere kenarliklari icin FloatBorder sabiti
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

-- Hover vb. islerin penceresini kenarlikli yap
local orig_util_open_floating_preview = vim.lsp.util.open_floating_preview
function vim.lsp.util.open_floating_preview(contents, syntax, opts, ...)
	opts = opts or {}
	opts.border = opts.border or border
	return orig_util_open_floating_preview(contents, syntax, opts, ...)
end

-- Otomatik tamamlama rengi ayarlayici
local function set_pmenu_hls()
	local function find_theme_color()
		local candidates = {
			"AyuOrange", "AyuYellow", "base46_ayu_orange", "base46_ayu_dark_orange",
			"Orange", "WarningMsg", "DiagnosticWarn", "Identifier", "Title", "Function",
		}
		for _, name in ipairs(candidates) do
			local ok, hl = pcall(vim.api.nvim_get_hl, 0, { name = name, link = false })
			if ok and hl then
				if hl.bg then return hl.bg
				elseif hl.fg then return hl.fg end
			end
		end
		return nil
	end

	pcall(vim.api.nvim_set_hl, 0, "Pmenu", { bg = "#000000", fg = "#dcdcdc" })

	local theme_col = find_theme_color()
	if theme_col then
		pcall(vim.api.nvim_set_hl, 0, "PmenuSel", { bg = theme_col, fg = "#000000", bold = true })
		pcall(vim.api.nvim_set_hl, 0, "CmpItemAbbrMatch", { fg = theme_col })
		pcall(vim.api.nvim_set_hl, 0, "CmpItemAbbrMatchFuzzy", { fg = theme_col })
	else
		pcall(vim.api.nvim_set_hl, 0, "PmenuSel", { bg = "#1e1e1e", fg = "#ffffff", bold = true })
	end

	pcall(vim.api.nvim_set_hl, 0, "PmenuSbar", { bg = "#0f0f0f" })
	pcall(vim.api.nvim_set_hl, 0, "PmenuThumb", { bg = "#1e1e1e" })

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

-- KOPYALAMADA PARLAMA EFEKTI (Yank Highlight)
vim.api.nvim_create_autocmd("TextYankPost", {
  group = vim.api.nvim_create_augroup("highlight_yank", { clear = true }),
  callback = function()
    vim.highlight.on_yank({ higroup = "IncSearch", timeout = 150 })
  end,
})

-- Q TUSU ILE ACILIR KAPANIR PENCERELERI HEMEN KAPATMA
vim.api.nvim_create_autocmd("FileType", {
  group = vim.api.nvim_create_augroup("close_with_q", { clear = true }),
  pattern = { "help", "lspinfo", "man", "notify", "qf", "query", "checkhealth" },
  callback = function(event)
    vim.bo[event.buf].buflisted = false
    vim.keymap.set("n", "q", "<cmd>close<cr>", { buffer = event.buf, silent = true })
  end,
})

-- TERMINAL VEYA PENCERE BUYUDUGUNDE SPLITLERI (BOLUNMUS ALANLARI) OTOMATIK AYARLA
vim.api.nvim_create_autocmd({ "VimResized" }, {
  group = vim.api.nvim_create_augroup("resize_splits", { clear = true }),
  callback = function()
    local current_tab = vim.fn.tabpagenr()
    vim.cmd("tabdo wincmd =")
    vim.cmd("tabnext " .. current_tab)
  end,
})

-- DOSYAYI ILK ACTIGINIZDA ESKI KALDIGINIZ YERDEN DEVAM ETME (Cursor Restore)
vim.api.nvim_create_autocmd("BufReadPost", {
  group = vim.api.nvim_create_augroup("last_loc", { clear = true }),
  callback = function(event)
    local exclude = { "gitcommit" }
    local buf = event.buf
    if vim.tbl_contains(exclude, vim.bo[buf].filetype) or vim.b[buf].lazyvim_last_loc then
      return
    end
    vim.b[buf].lazyvim_last_loc = true
    local mark = vim.api.nvim_buf_get_mark(buf, '"')
    local lcount = vim.api.nvim_buf_line_count(buf)
    if mark[1] > 0 and mark[1] <= lcount then
      pcall(vim.api.nvim_win_set_cursor, 0, mark)
    end
  end,
})
