-- folke
-- require("folke.config.lazy")

-- gordon
vim.opt.rtp:prepend(vim.fn.stdpath("config") .. "/lua/gordon")
require("gordon.init")

-- nvchad
-- local nvchad_path = vim.fn.stdpath("config") .. "/lua/nvchad/nvstarter"
-- vim.opt.rtp:prepend(nvchad_path)
-- local configs_lazy = dofile(nvchad_path .. "/lua/configs/lazy.lua")
-- configs_lazy.performance = configs_lazy.performance or {}
-- configs_lazy.performance.rtp = configs_lazy.performance.rtp or {}
-- configs_lazy.performance.rtp.paths = { nvchad_path }
-- package.loaded["configs.lazy"] = configs_lazy
-- require("nvchad.nvstarter.init")