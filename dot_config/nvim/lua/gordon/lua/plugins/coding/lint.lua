return {
	"mfussenegger/nvim-lint",
	event = { "BufReadPost", "BufNewFile", "BufWritePre" },
	config = function()
		local lint = require("lint")
		
		-- Linters tanimlamasi (basitlestirildi)
		lint.linters_by_ft = {
			lua = { "luacheck" },
			c = { "cpplint" },
			cpp = { "cpplint" },
		}

		local lint_augroup = vim.api.nvim_create_augroup("UserLint", { clear = true })
        
		-- Debounce mantigi: surekli tetiklenmeyi engeller ve arayuz kasmalarini yok eder
		local timer = nil
		local function try_lint()
			if timer then
				timer:stop()
			end
			timer = (vim.uv or vim.loop).new_timer()
			timer:start(500, 0, vim.schedule_wrap(function()
				local ft = vim.bo.filetype
				local configured_linters = lint.linters_by_ft[ft]
				
				if not configured_linters or type(configured_linters) ~= "table" then
					return
				end
				
				-- Sadece halihazirda yuklu olan programlari dene
				local available_linters = {}
				for _, linter in ipairs(configured_linters) do
					if vim.fn.executable(linter) == 1 then
						table.insert(available_linters, linter)
					end
				end
				
				-- Pcall sayesinde linter patlasa bile ekrana kirmizi yazi basmaz (defansif)
				if #available_linters > 0 then
					pcall(function()
						lint.try_lint(available_linters)
					end)
				end
			end))
		end

		vim.api.nvim_create_autocmd({ "BufWritePost", "BufReadPost", "InsertLeave", "TextChanged" }, {
			group = lint_augroup,
			callback = try_lint,
		})

		vim.api.nvim_create_user_command("Lint", function() try_lint() end, {})
	end,
}
