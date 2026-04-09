return {
    {
        "norcalli/nvim-colorizer.lua",
        event = { "BufRead", "BufNewFile" },
        config = function()
            require("colorizer").setup({ "*" }, {
                RGB = true,
                names = true,
                tailwind = true,
                mode = "background",
            })
        end,
    },
}
