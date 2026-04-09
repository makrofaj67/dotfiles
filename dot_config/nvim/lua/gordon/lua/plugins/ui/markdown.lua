return {
	-- Neovim icerisinde Markdown kodlarini harika, renkli grafiker / icon tabanli bir okunusa cevirir
	{
		"MeanderingProgrammer/render-markdown.nvim",
		dependencies = { "nvim-treesitter/nvim-treesitter", "nvim-tree/nvim-web-devicons" },
		ft = { "markdown", "norg", "rmd", "org" },
		opts = {
			-- Daha kalin ve gercekci baslik seviyeleri (Heading sizes)
			heading = {
				enabled = true,
				icons = { "󰲡 ", "󰲣 ", "󰲥 ", "󰲧 ", "󰲩 ", "󰲫 " },
				position = "overlay",
				backgrounds = {
					"RenderMarkdownH1Bg",
					"RenderMarkdownH2Bg",
					"RenderMarkdownH3Bg",
					"RenderMarkdownH4Bg",
					"RenderMarkdownH5Bg",
					"RenderMarkdownH6Bg",
				},
				foregrounds = {
					"RenderMarkdownH1",
					"RenderMarkdownH2",
					"RenderMarkdownH3",
					"RenderMarkdownH4",
					"RenderMarkdownH5",
					"RenderMarkdownH6",
				},
			},
			dash = { enabled = true, icon = "─", width = "full" },
			bullet = {
				enabled = true,
				icons = { "●", "○", "◆", "◇" },
			},
			checkbox = {
				enabled = true,
				unchecked = { icon = "󰄱" },
				checked = { icon = "󰱒" },
				custom = {
					todo = { raw = "[-]", rendered = "󰥔", highlight = "RenderMarkdownTodo" },
				},
			},
		},
	},

	-- Tarayicida Github tasarimi ve stili ile inanilmaz bir anlik Canli-Onizleme (Preview) Sunucusu yaratir
	{
		"iamcco/markdown-preview.nvim",
		cmd = { "MarkdownPreviewToggle", "MarkdownPreview", "MarkdownPreviewStop" },
		build = function()
			vim.fn["mkdp#util#install"]()
		end,
		ft = { "markdown" },
		keys = {
			{ "<leader>mp", "<cmd>MarkdownPreviewToggle<cr>", desc = "Markdown Onizleme (Tarayici)" },
		},
		config = function()
			-- Theme auto (Github)
			vim.g.mkdp_theme = "dark"
		end,
	},
}
