vim.pack.add({
    -- Ana Pluginler ve Bağımlılıklar
    {
        src = 'https://github.com/nvim-neo-tree/neo-tree.nvim',
        version = vim.version.range('3')
    },
    "https://github.com/nvim-lua/plenary.nvim",
    "https://github.com/MunifTanjim/nui.nvim",
    "https://github.com/nvim-tree/nvim-web-devicons",

})
-- Neo-tree'yi de başlatmayı unutmayın (isteğe bağlı)
require("neo-tree").setup({})
