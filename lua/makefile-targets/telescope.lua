local M = {}

--- Open a Telescope picker for Makefile targets.
--- Supports toggling dry run mode with <C-d> without closing the picker.
---
--- Keymaps inside the picker:
---   <CR>    Run the selected target
---   <C-d>   Toggle dry run mode (make -n)
---
---@param opts PickTargetOpts|nil
function M.pick_target(opts)
    local ok, telescope = pcall(require, "telescope")
    if not ok then
        vim.notify(
            "makefile-targets: telescope.nvim is required for this picker",
            vim.log.levels.ERROR
        )
        return
    end

    local pickers = require("telescope.pickers")
    local finders = require("telescope.finders")
    local conf = require("telescope.config").values
    local actions = require("telescope.actions")
    local action_state = require("telescope.actions.state")

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

    local function make_finder()
        return finders.new_table({
            results = targets,
            entry_maker = function(item)
                local display = item.desc and (item.target .. "  " .. item.desc) or item.target
                return {
                    value = item,
                    display = display,
                    ordinal = item.target,
                }
            end,
        })
    end

    local function prompt_title()
        return dry_run and "Make target  [dry run: on]" or "Make target"
    end

    pickers
        .new({}, {
            prompt_title = prompt_title(),
            finder = make_finder(),
            sorter = conf.generic_sorter({}),
            previewer = false,
            attach_mappings = function(prompt_bufnr, map)
                -- <CR> runs the target
                actions.select_default:replace(function()
                    actions.close(prompt_bufnr)
                    local selection = action_state.get_selected_entry()
                    if selection then
                        local args = dry_run and "-n" or config.make_args
                        core.run_target(selection.value.target, dir, args)
                    end
                end)

                -- <C-d> toggles dry run and refreshes the prompt title
                map({ "i", "n" }, "<C-d>", function()
                    dry_run = not dry_run
                    local current_picker = action_state.get_current_picker(prompt_bufnr)
                    current_picker.prompt_border:change_title(prompt_title())
                end)

                return true
            end,
        })
        :find()
end

return M
