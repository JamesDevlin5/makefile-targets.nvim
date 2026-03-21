---@module "makefile-targets"
local M = {}

---@class MakefileTargetsOpts
---@field makefile_name? string Filename to search for
---@field finders? string[] Ordered list of root finders: "lsp", "git", "buffer", "cwd"
---@field desc_prefix? string Comment prefix used to identify target descriptions
---@field make_cmd? string The make executable to invoke (e.g. "make", "gmake")
---@field make_args? string Extra arguments appended after the executable and before the target

--- Default Config
M.config = {
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
end

return M
