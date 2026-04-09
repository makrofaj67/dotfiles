return {
	"mfussenegger/nvim-lint",
	event = { "BufReadPost", "BufNewFile" },
	config = function()
		local lint = require("lint")
		local function has(bin)
			return vim.fn.executable(bin) == 1
		end

		local by_ft = {}
		if has("luacheck") then
			by_ft.lua = { "luacheck" }
		end
		if has("cpplint") then
			by_ft.c = { "cpplint" }
			by_ft.cpp = { "cpplint" }
		end

		lint.linters_by_ft = vim.tbl_extend("force", lint.linters_by_ft or {}, by_ft)

		local group = vim.api.nvim_create_augroup("UserLint", { clear = true })
		local function try_lint()
			local ft = vim.bo.filetype
			local configured = lint.linters_by_ft[ft]
			if configured and next(configured) ~= nil then
				lint.try_lint()
			end
		end
		vim.api.nvim_create_autocmd({ "BufWritePost", "InsertLeave", "TextChanged" }, {
			group = group,
			callback = try_lint,
		})

		vim.api.nvim_create_user_command("Lint", function() lint.try_lint() end, {})
	end,
}
