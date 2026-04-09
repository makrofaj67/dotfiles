return {
	"stevearc/conform.nvim",
	event = { "BufWritePre" },
	opts = {
		-- Defansif format-on-save: Eger formatter bozuksa kayit islemini baltalamaz
		format_on_save = function(bufnr)
			if vim.g.disable_autoformat or vim.b[bufnr].disable_autoformat then
				return
			end
			-- Asiri buyuk dosyalarda (or. >1MB) kasmayi onlemek icin iptal
			local file = vim.api.nvim_buf_get_name(bufnr)
			local ok, stats = pcall((vim.uv or vim.loop).fs_stat, file)
			if ok and stats and stats.size > 1024 * 1024 then
				return
			end
			
			return { timeout_ms = 1000, lsp_fallback = true, quiet = true }
		end,
		formatters_by_ft = {
			lua = { "stylua" },
		},
	},
}
