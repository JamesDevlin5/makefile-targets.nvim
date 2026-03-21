local M = {}

--- Open a Mini.pick picker for Makefile targets.
--- Press <Tab> to toggle the recipe preview.
--- Press <C-d> to toggle dry run mode.
---
---@param opts PickTargetOpts|nil
function M.pick_target(opts)
    local ok, mini_pick = pcall(require, "mini.pick")
    if not ok then
        vim.notify("makefile-targets: mini.pick is required for this picker", vim.log.levels.ERROR)
        return
    end

    local core = require("makefile-targets.core")
    local config = require("makefile-targets").config

    local targets, dir = core.parse_targets()
    if #targets == 0 then
        vim.notify("makefile-targets: No targets found", vim.log.levels.INFO)
        return
    end
    assert(dir, "makefile-targets: dir should not be nil when targets were found")

    local make_args = (opts and opts.make_args ~= nil) and opts.make_args or config.make_args
    local dry_run = make_args == "-n"

    local function prompt_title()
        return dry_run and "Make target  [dry run: on]" or "Make target"
    end

    -- Items are tables with a `text` field — mini.pick uses this for display and matching
    local items = vim.tbl_map(function(t)
        return {
            text = t.desc and (t.target .. " - " .. t.desc) or t.target,
            data = t,
        }
    end, targets)

    mini_pick.start({
        source = {
            items = items,
            name = prompt_title(),

            -- preview is called when the user presses <Tab> to toggle preview
            preview = function(buf_id, item)
                if not item then
                    return
                end
                local t = item.data
                local lines = {}
                table.insert(lines, t.target .. ":")
                if t.desc then
                    table.insert(lines, "    " .. t.desc)
                end
                table.insert(lines, "")
                if #t.recipe > 0 then
                    for _, cmd in ipairs(t.recipe) do
                        table.insert(lines, "\t" .. cmd)
                    end
                else
                    table.insert(lines, "  (no recipe)")
                end
                vim.api.nvim_buf_set_lines(buf_id, 0, -1, false, lines)
                vim.bo[buf_id].filetype = "make"
            end,

            choose = function(item)
                if not item then
                    return
                end
                local args = dry_run and "-n" or config.make_args
                core.run_target(item.data.target, dir, args)
            end,
        },

        mappings = {
            toggle_dry_run = {
                char = "<C-d>",
                func = function()
                    dry_run = not dry_run
                    -- Refresh the picker name to reflect new state
                    mini_pick.set_picker_opts({ source = { name = prompt_title() } })
                end,
            },
        },
    })
end

return M
