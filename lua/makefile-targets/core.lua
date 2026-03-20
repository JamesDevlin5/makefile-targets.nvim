local M = {}

--- Wrapper around vim.notify that prefixes every message with the plugin name.
---@param msg string
---@param level integer One of vim.log.levels.*
local function notify(msg, level)
    vim.notify("makefile-targets: " .. msg, level)
end

--- Resolve a starting directory for the Makefile search.
---@return string
local function get_search_root()
    -- Start with LSP
    local clients = vim.lsp.get_clients({ bufnr = 0 })
    if #clients > 0 then
        local root = clients[1].config.root_dir
        if root then
            return root
        end
    end

    -- Fall back to git repo root
    local git_root = vim.fn.systemlist("git rev-parse --show-toplevel")[1]
    if vim.v.shell_error == 0 and git_root and git_root ~= "" then
        return git_root
    end

    -- Fall back to the directory of the current file
    local bufpath = vim.api.nvim_buf_get_name(0)
    if bufpath ~= "" then
        return vim.fn.fnamemodify(bufpath, ":h")
    end

    -- Fall back to vim cwd
    return vim.fn.getcwd()
end

--- Search for a Makefile by walking upward from start_dir.
--- Returns the full path if found, or nil.
---@param start_dir string
---@param filename string
---@return string|nil
local function find_makefile(start_dir, filename)
    local results = vim.fs.find(filename, {
        upward = true,
        path = start_dir,
        type = "file",
        limit = 1,
    })
    return results[1]
end

--- Find and parse targets from a Makefile.
--- A target line looks like:  `my-target:` or `my-target: dep1 dep2`
--- Lines starting with `.` (like .PHONY) are excluded.
---@return string[] List of target names, or empty list if none found
local function parse_targets()
    local config = require("makefile-targets").config
    local root = get_search_root()
    local path = find_makefile(root, config.makefile_name)

    if not path then
        notify(
            "No " .. config.makefile_name .. " found (searched upward from " .. root .. ")",
            vim.log.levels.WARN
        )
        return {}
    end

    local targets = {}
    for _, line in ipairs(vim.fn.readfile(path)) do
        -- Match lines like "target-name:" that don't start with a tab or dot
        local target = line:match("^([%w][%w%-_]*):")
        if target then
            table.insert(targets, target)
        end
    end

    return targets
end

--- Run a Makefile target in a terminal split.
---@param target string The target name to run
local function run_target(target)
    vim.cmd("botright new")
    vim.fn.jobstart("make " .. target, { term = true })
    vim.api.nvim_buf_set_name(0, "make:" .. target)
    vim.cmd("startinsert")
end

--- Open a picker showing available Makefile targets.
--- Selecting one runs it via `make <target>` in a terminal split.
function M.pick_target()
    local targets = parse_targets()

    if #targets == 0 then
        notify("No targets found", vim.log.levels.INFO)
        return
    end

    vim.ui.select(targets, {
        prompt = "Make target:",
    }, function(choice)
        if choice then
            run_target(choice)
        end
    end)
end

return M
