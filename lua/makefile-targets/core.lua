local M = {}

--- Wrapper around vim.notify that prefixes every message with the plugin name.
---@param msg string
---@param level integer One of vim.log.levels.*
local function notify(msg, level)
    vim.notify("makefile-targets: " .. msg, level)
end

--- Resolve a starting directory for the Makefile search.
local finders = {
    lsp = function()
        local clients = vim.lsp.get_clients({ bufnr = 0 })
        if #clients > 0 then
            return clients[1].config.root_dir
        end
    end,

    git = function()
        local result = vim.fn.systemlist("git rev-parse --show-toplevel")[1]
        if vim.v.shell_error == 0 and result and result ~= "" then
            return result
        end
    end,

    buffer = function()
        local bufpath = vim.api.nvim_buf_get_name(0)
        if bufpath ~= "" then
            return vim.fn.fnamemodify(bufpath, ":h")
        end
    end,

    cwd = function()
        return vim.fn.getcwd()
    end,
}
--- Try each finder, returning the first non-nil result.
---@return string
local function get_search_root()
    local config = require("makefile-targets").config
    for _, name in ipairs(config.finders) do
        local finder = finders[name]
        if not finder then
            notify("Unknown finder: " .. name, vim.log.levels.WARN)
        else
            local root = finder()
            if root then
                return root
            end
        end
    end
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
---@return string[] targets
---@return string|nil dir Directory containing the Makefile, or nil if not found
local function parse_targets()
    local config = require("makefile-targets").config
    local root = get_search_root()
    local path = find_makefile(root, config.makefile_name)

    if not path then
        notify(
            "No " .. config.makefile_name .. " found (searched upward from " .. root .. ")",
            vim.log.levels.WARN
        )
        return {}, nil
    end

    local targets = {}
    for _, line in ipairs(vim.fn.readfile(path)) do
        -- Match lines like "target-name:" that don't start with a tab or dot
        local target = line:match("^([%w][%w%-_]*):")
        if target then
            table.insert(targets, target)
        end
    end

    return targets, vim.fn.fnamemodify(path, ":h")
end

--- Run a Makefile target in a terminal split.
---@param target string The target name to run
---@param dir string The directory containing the Makefile
local function run_target(target, dir)
    vim.cmd("botright new")
    vim.fn.jobstart("make " .. target, { term = true, cwd = dir })
    vim.api.nvim_buf_set_name(0, "make:" .. target)
    vim.cmd("startinsert")
end

--- Open a picker showing available Makefile targets.
--- Selecting one runs it via `make <target>` in a terminal split.
function M.pick_target()
    local targets, dir = parse_targets()

    if #targets == 0 then
        notify("No targets found", vim.log.levels.INFO)
        return
    end

    vim.ui.select(targets, {
        prompt = "Make target:",
    }, function(choice)
        if choice then
            assert(dir, "makefile-targets: dir should not be nil when targets were found")
            run_target(choice, dir)
        end
    end)
end

return M

