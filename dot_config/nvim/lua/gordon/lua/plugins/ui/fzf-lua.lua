return {
  "ibhagwan/fzf-lua",
  cmd = "FzfLua",
  dependencies = { "nvim-tree/nvim-web-devicons" },
  opts = function(_, opts)
    -- Telescope/NvChad tarzi yuvarlak koseler
    opts.winopts = {
      backdrop = 100,
      border = "rounded",
      preview = {
        border = "rounded",
        layout = "flex",
      },
    }
    opts.fzf_colors = true
    return opts
  end,
  keys = {
    { "<leader>ff", "<cmd>FzfLua files<cr>", desc = "Dosya Ara" },
    { "<leader>fg", "<cmd>FzfLua live_grep<cr>", desc = "Metin Ara (Grep)" },
    { "<leader>fb", "<cmd>FzfLua buffers<cr>", desc = "Buffer Ara" },
    { "<leader>fh", "<cmd>FzfLua help_tags<cr>", desc = "Yardim Ara" },
    { "<leader>sk", "<cmd>FzfLua keymaps<cr>", desc = "Kisaayol Ara" },
    { "<leader>sd", "<cmd>FzfLua diagnostics_document<cr>", desc = "Diagnostic Ara (Belge)" },
    { "<leader>sD", "<cmd>FzfLua diagnostics_workspace<cr>", desc = "Diagnostic Ara (Workspace)" },
    { "<leader>sr", "<cmd>FzfLua resume<cr>", desc = "Son Aramaya Don" },
    { "<leader>sn", "<cmd>FzfLua files cwd=" .. vim.fn.stdpath("config") .. "<cr>", desc = "Neovim Ayarlarinda Ara" },
    { "<leader>th", "<cmd>FzfLua colorschemes<cr>", desc = "Tema Secici (Base46)" },
    -- Eski <leader>/ telafi edelim:
    { "<leader><space>", "<cmd>FzfLua files<cr>", desc = "Hizli Dosya Bul" },
    { "<leader>/", "<cmd>FzfLua fzf_grep<cr>", desc = "Grep Hizli Ara" },
  },
}
