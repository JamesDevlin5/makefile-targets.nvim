local M = {}

--- Wrapper around vim.notify that prefixes every message with the plugin name.
---@param msg string
---@param level integer One of vim.log.levels.*
local function notify(msg, level)
    vim.notify("makefile-targets: " .. msg, level)
end

--- Available root finders, keyed by name.
--- Each returns a string path or nil if it can't resolve a root.
local finders = {
    lsp = function()
        local clients = vim.lsp.get_clients({ bufnr = 0 })
        if #clients > 0 then
            return clients[1].config.root_dir
        end
    end,

    git = function()
        local result = vim.system({ "git", "rev-parse", "--show-toplevel" }, { text = true }):wait()
        if result.code == 0 and result.stdout and result.stdout ~= "" then
            return vim.trim(result.stdout)
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

--- A parsed Makefile target.
---@class MakefileTarget
---@field target string The target name
---@field desc string|nil Description from the commend above the target

--- Find and parse targets from a Makefile.
--- A target line looks like:  `my-target:` or `my-target: dep1 dep2`
--- Lines starting with `.` (like .PHONY) are excluded.
---@return MakefileTarget[] targets
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
    local lines = vim.fn.readfile(path)
    local prefix = vim.pesc(config.desc_prefix)

    for i, line in ipairs(lines) do
        local target = line:match("^([%w][%w%-_]*):")
        if target then
            -- Walk backward collecting all consecutive prefixed comment lines
            local desc_lines = {}
            local j = i - 1
            while j >= 1 do
                local d = lines[j]:match("^" .. prefix .. "%s*(.*)")
                if d then
                    table.insert(desc_lines, 1, d)
                    j = j - 1
                else
                    break
                end
            end
            local desc = #desc_lines > 0 and table.concat(desc_lines, " ") or nil
            table.insert(targets, { target = target, desc = desc })
        end
    end

    return targets, vim.fn.fnamemodify(path, ":h")
end

--- Run a Makefile target in a terminal split.
---@param target string The target name to run
---@param dir string The directory containing the Makefile
---@param make_args string Extra arguments to pass to make (e.g. "-n", "-j4")
local function run_target(target, dir, make_args)
    local config = require("makefile-targets").config
    local args = make_args ~= "" and make_args .. " " or ""
    local cmd = config.make_cmd .. " " .. args .. target
    local label = make_args ~= "" and "make:" .. target .. " [" .. make_args .. "]"
        or "make:" .. target
    vim.cmd("botright new")
    vim.fn.jobstart(cmd, { term = true, cwd = dir })
    vim.api.nvim_buf_set_name(0, label)
    vim.cmd("startinsert")
end

--- Options for pick_target.
---@class PickTargetOpts
---@field make_args string|nil Extra args to pass to make, overrides config.make_args

--- Open a picker showing available Makefile targets.
--- Selecting one runs it via `make [make_args] <target>` in a terminal split.
---@param opts PickTargetOpts|nil
function M.pick_target(opts)
    local config = require("makefile-targets").config
    local make_args = (opts and opts.make_args ~= nil) and opts.make_args or config.make_args
    local targets, dir = parse_targets()

    if #targets == 0 then
        notify("No targets found", vim.log.levels.INFO)
        return
    end

    vim.ui.select(targets, {
        prompt = "Make target:",
        format_item = function(item)
            if item.desc then
                return item.target .. " - " .. item.desc
            end
            return item.target
        end,
    }, function(choice)
        if choice then
            assert(dir, "makefile-targets: dir should not be nil when targets were found")
            run_target(choice.target, dir, make_args)
        end
    end)
end

return M
