-- Minimal Neovim config used only during test runs.
-- Adds plenary and this plugin to the runtimepath, nothing else.

local plenary_path = vim.fn.stdpath("data") .. "/lazy/plenary.nvim"
local plugin_path = vim.fn.fnamemodify(debug.getinfo(1).source:sub(2), ":h:h")

-- Auto-install plenary if missing
if vim.fn.isdirectory(plenary_path) == 0 then
    vim.fn.system({
        "git",
        "clone",
        "--depth=1",
        "https://github.com/nvim-lua/plenary.nvim",
        plenary_path,
    })
end

vim.opt.runtimepath:append(plenary_path)
vim.opt.runtimepath:append(plugin_path)

-- Source plenary's bundled test helpers
vim.cmd("runtime plugin/plenary.vim")
