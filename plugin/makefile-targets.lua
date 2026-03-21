-- This file is sourced automatically by Neovim on startup.

-- Expose a :MakefileTargets command as an alternative to the keymap
vim.api.nvim_create_user_command("MakefileTargets", function()
    require("makefile-targets.core").pick_target()
end, { desc = "Pick and run a Makefile target" })

-- Runs the previous Makefile command
vim.api.nvim_create_user_command("MakefileTargetsRunLast", function()
    require("makefile-targets.core").run_last_target()
end, { desc = "Re-run the last Makefile target" })
