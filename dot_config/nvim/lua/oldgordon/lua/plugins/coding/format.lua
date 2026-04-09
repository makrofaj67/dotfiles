return {
	"stevearc/conform.nvim",
	event = { "BufWritePre" },
	opts = {
		-- format_on_save = function(bufnr)
		-- 	local ok, stats = pcall(vim.loop.fs_stat, vim.api.nvim_buf_get_name(bufnr))
		-- 	if ok and stats and stats.size > 256 * 1024 then
		-- 		return nil
		-- 	end
		-- 	return { timeout_ms = 1000, lsp_fallback = true }
		-- end,
		formatters_by_ft = {
			lua = { "stylua" },
		},
	},
}
