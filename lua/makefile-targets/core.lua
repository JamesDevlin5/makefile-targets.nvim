local M = {}

--- Wrapper around vim.notify that prefixes every message with the plugin name.
---@param msg string
---@param level integer One of vim.log.levels.*
local function notify(msg, level)
    vim.notify("makefile-targets: " .. msg, level)
end

--- Find and parse targets from a Makefile.
--- A target line looks like:  `my-target:` or `my-target: dep1 dep2`
--- Lines starting with `.` (like .PHONY) are excluded.
---@return string[] List of target names (empty if none found)
local function parse_targets()
	local config = require("makefile-targets").config
	local path = vim.fn.getcwd() .. "/" .. config.makefile_name

	if vim.fn.filereadable(path) == 0 then
		notify("No Makefile found at " .. path, vim.log.levels.WARN)
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
