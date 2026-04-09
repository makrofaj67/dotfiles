return {
	"lewis6991/gitsigns.nvim",

	event = "BufReadPost",

	opts = {
		signs = {
			add = { text = "│" },
			change = { text = "│" },
			delete = { text = "▔" },
			topdelete = { text = "▔" },
			changedelete = { text = "│" },
			untracked = { text = "┆" },
		},

		on_attach = function(bufnr)
			local gs = package.loaded.gitsigns
			local function map(mode, l, r, opts)
				opts = opts or {}
				opts.buffer = bufnr
				vim.keymap.set(mode, l, r, opts)
			end

			map("n", "]c", function()
				if vim.wo.diff then return "]c" end
				vim.schedule(function() gs.next_hunk() end)
				return "<Ignore>"
			end, { expr = true, desc = "Sonraki Git Değişikliği (Hunk)" })

			map("n", "[c", function()
				if vim.wo.diff then return "[c" end
				vim.schedule(function() gs.prev_hunk() end)
				return "<Ignore>"
			end, { expr = true, desc = "Önceki Git Değişikliği (Hunk)" })

			map("n", "<leader>gs", gs.stage_hunk, { desc = "Git: Değişikliği Stage'le" })
			map("n", "<leader>gr", gs.reset_hunk, { desc = "Git: Değişikliği Geri Al" })
			map("v", "<leader>gs", function() gs.stage_hunk({ vim.fn.line("."), vim.fn.line("v") }) end,
				{ desc = "Git: Seçili Alanı Stage'le" })
			map("v", "<leader>gr", function() gs.reset_hunk({ vim.fn.line("."), vim.fn.line("v") }) end,
				{ desc = "Git: Seçili Alanı Geri Al" })

			map("n", "<leader>gp", gs.preview_hunk, { desc = "Git: Değişikliği Önizle" })
			map("n", "<leader>gb", gs.blame_line, { desc = "Git: Satır Bilgisi (Blame)" })
		end,
	},
}
