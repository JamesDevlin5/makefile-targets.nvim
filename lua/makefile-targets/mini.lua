local M = {}

--- Open a Mini.pick picker for Makefile targets.
--- Supports toggling dry run mode with <C-d> without closing the picker.
---
--- Keymaps inside the picker:
---   <CR>    Run the selected target
---   <C-d>   Toggle dry run mode (make -n)
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

    -- Dry run state — starts from opts or config
    local make_args = (opts and opts.make_args ~= nil) and opts.make_args or config.make_args
    local dry_run = make_args == "-n"

    local function prompt_title()
        return dry_run and "Make target  [dry run: on]" or "Make target"
    end

    -- Build items list — mini.pick works with plain strings, so we carry the
    -- original table in a parallel list and use the index to look it up.
    local items = vim.tbl_map(function(t)
        return t.desc and (t.target .. "  " .. t.desc) or t.target
    end, targets)

    mini_pick.start({
        source = {
            items = items,
            name = prompt_title(),
            choose = function(item)
                -- Find the matching target by display string
                local chosen = nil
                for _, t in ipairs(targets) do
                    local display = t.desc and (t.target .. "  " .. t.desc) or t.target
                    if display == item then
                        chosen = t
                        break
                    end
                end
                if chosen then
                    local args = dry_run and "-n" or config.make_args
                    core.run_target(chosen.target, dir, args)
                end
            end,
        },
        mappings = {
            toggle_dry_run = {
                char = "<C-d>",
                func = function()
                    dry_run = not dry_run
                    -- Update the picker title to reflect the new state
                    local picker = mini_pick.get_picker_state()
                    if picker then
                        mini_pick.set_picker_opts({ source = { name = prompt_title() } })
                    end
                end,
            },
        },
    })
end

return M
