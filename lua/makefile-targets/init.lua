---@module "makefile-targets"
local M = {}

---@class MakefileTargetsOpts
---@field keymap? string|false Normal-mode keymap for the picker, or false to disable
---@field dry_run_keymap? string|false Normal-mode keymap for the dry run picker, or false to disable
---@field telescope_keymap? string|false Normal-mode keymap for the Telescope picker, or false to disable
---@field mini_keymap? string|false Normal-mode keymap for the Mini.pick picker, or false to disable
---@field makefile_name? string Filename to search for
---@field finders? string[] Ordered list of root finders: "lsp", "git", "buffer", "cwd"
---@field desc_prefix? string Comment prefix used to identify target descriptions
---@field make_cmd? string The make executable to invoke (e.g. "make", "gmake")
---@field make_args? string Extra arguments appended after the executable and before the target

--- Default Config
M.config = {
    -- Triggers the picker (set to false to disable)
    keymap = "<Leader>m",
    -- Keymap to trigger the picker in dry run mode (set to false to disable)
    dry_run_keymap = false,
    -- Keymap to trigger the Telescope picker (set to false to disable)
    telescope_keymap = false,
    -- Keymap to trigger the Mini.pick picker (set to false to disable)
    mini_keymap = false,
    -- Makefile location (relative to cwd)
    makefile_name = "Makefile",
    -- Order in which root finders are tried. Available: "lsp", "git", "buffer", "cwd"
    finders = { "lsp", "git", "buffer", "cwd" },
    -- Comment prefix used to identify target descriptions
    desc_prefix = "##",
    -- The make executable to invoke
    make_cmd = "make",
    -- Extra arguments passed to make before the target (e.g. "-j4", "-n")
    make_args = "",
}

--- Setup Function
---@param opts MakefileTargetsOpts|nil Optional config overrides
function M.setup(opts)
    M.config = vim.tbl_deep_extend("force", M.config, opts or {})

    if M.config.keymap then
        vim.keymap.set("n", M.config.keymap, function()
            require("makefile-targets.core").pick_target()
        end, { desc = "Pick a Makefile target" })
    end

    if M.config.dry_run_keymap then
        vim.keymap.set("n", M.config.dry_run_keymap, function()
            require("makefile-targets.core").pick_target({ make_args = "-n" })
        end, { desc = "Pick a Makefile target (dry run)" })
    end

    if M.config.telescope_keymap then
        vim.keymap.set("n", M.config.telescope_keymap, function()
            require("makefile-targets.telescope").pick_target()
        end, { desc = "Pick a Makefile target (Telescope)" })
    end

    if M.config.mini_keymap then
        vim.keymap.set("n", M.config.mini_keymap, function()
            require("makefile-targets.mini").pick_target()
        end, { desc = "Pick a Makefile target (Mini.pick)" })
    end
end

return M
