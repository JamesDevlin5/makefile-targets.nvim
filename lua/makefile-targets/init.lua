local M = {}

---@class MakefileTargetsOpts
---@field keymap string|false Normal-mode keymap for the picker, or false to disable
---@field makefile_name string Filename to search for
---@field finders string[] Ordered list of root finders: "lsp", "git", "buffer", "cwd"

--- Default Config
M.config = {
    -- Triggers the picker (set to false to disable)
    keymap = "<Leader>m",
    -- Makefile location (relative to cwd)
    makefile_name = "Makefile",
    -- Order in which root finders are tried. Available: "lsp", "git", "buffer", "cwd"
    finders = { "lsp", "git", "buffer", "cwd" },
}

--- Setup Function
---@param opts table|nil Optional config overrides
function M.setup(opts)
    M.config = vim.tbl_deep_extend("force", M.config, opts or {})

    -- register keymap
    if M.config.keymap then
        vim.keymap.set("n", M.config.keymap, function()
            require("makefile-targets.core").pick_target()
        end, { desc = "Pick a Makefile target" })
    end
end

return M
