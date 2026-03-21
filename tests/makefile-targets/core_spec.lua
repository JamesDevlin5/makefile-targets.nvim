-- Tests for lua/makefile-targets/core.lua

local assert = require("luassert")

--- Write a temp file and return its path and parent directory.
---@param filename string
---@param contents string
---@return string path
---@return string dir
local function write_tmp(filename, contents)
    local dir = vim.fn.tempname() -- unique temp dir path
    vim.fn.mkdir(dir, "pF")
    local path = dir .. "/" .. filename
    vim.fn.writefile(vim.split(contents, "\n"), path)
    return path, dir
end

--- Extract the target names from a list of MakefileTarget tables.
---@param items MakefileTarget[]
---@return string[]
local function targets(items)
    return vim.tbl_map(function(t)
        return t.target
    end, items or {})
end

--- Find a target by name in MakefileTarget tables.
---@param items MakefileTarget[]
---@param target string
---@return MakefileTarget|nil
local function find_target(items, target)
    for _, t in ipairs(items or {}) do
        if t.target == target then
            return t
        end
    end
end

describe("parse_targets (via pick_target smoke path)", function()
    local captured
    local notified

    before_each(function()
        captured = nil
        notified = {}
        package.loaded["makefile-targets"] = nil
        package.loaded["makefile-targets.core"] = nil
        require("makefile-targets").setup({ finders = { "buffer" } })
        ---@diagnostic disable-next-line: duplicate-set-field
        vim.ui.select = function(items, _, _)
            captured = items
        end
        ---@diagnostic disable-next-line: duplicate-set-field
        vim.notify = function(msg, _)
            table.insert(notified, msg)
        end
    end)

    after_each(function()
        vim.ui.select = nil
        vim.notify = nil
    end)

    it("finds simple targets in a Makefile", function()
        local _, dir = write_tmp(
            "Makefile",
            table.concat({
                "build: src/main.c",
                "\tgcc -o build src/main.c",
                "",
                "clean:",
                "\trm -f build",
                "",
                "test: build",
                "\t./build --test",
            }, "\n")
        )

        require("makefile-targets").config.makefile_name = "Makefile"
        vim.api.nvim_buf_set_name(0, dir .. "/fake.c")

        require("makefile-targets.core").pick_target()

        assert.are.same({ "build", "clean", "test" }, targets(captured))
        assert.are.equal(0, #notified)
    end)

    it("ignores .PHONY and variable assignment lines", function()
        local _, dir = write_tmp(
            "Makefile",
            table.concat({
                ".PHONY: all clean",
                "CC = gcc",
                "all: main.c",
                "\t$(CC) -o all main.c",
                "clean:",
                "\trm all",
            }, "\n")
        )

        require("makefile-targets").config.makefile_name = "Makefile"
        vim.api.nvim_buf_set_name(0, dir .. "/fake.c")

        require("makefile-targets.core").pick_target()

        local ns = targets(captured)
        assert.is_false(vim.tbl_contains(ns, ".PHONY"))
        assert.is_false(vim.tbl_contains(ns, "CC"))
        assert.is_truthy(vim.tbl_contains(ns, "all"))
        assert.is_truthy(vim.tbl_contains(ns, "clean"))
    end)

    it("warns and returns early when no Makefile is found", function()
        local empty_dir = vim.fn.tempname()
        vim.fn.mkdir(empty_dir, "pF")

        require("makefile-targets").config.makefile_name = "Makefile"
        vim.api.nvim_buf_set_name(0, empty_dir .. "/fake.c")

        require("makefile-targets.core").pick_target()

        assert.is_true(#notified > 0)
        assert.is_nil(captured)
    end)
end)

describe("target descriptions", function()
    local captured
    local notified

    before_each(function()
        captured = nil
        notified = {}
        package.loaded["makefile-targets"] = nil
        package.loaded["makefile-targets.core"] = nil
        require("makefile-targets").setup({ finders = { "buffer" } })
        ---@diagnostic disable-next-line: duplicate-set-field
        vim.ui.select = function(items, _, _)
            captured = items
        end
        ---@diagnostic disable-next-line: duplicate-set-field
        vim.notify = function(msg, _)
            table.insert(notified, msg)
        end
    end)

    after_each(function()
        vim.ui.select = nil
        vim.notify = nil
    end)

    it("parses a ## description from the line above a target", function()
        local _, dir = write_tmp(
            "Makefile",
            table.concat({
                "## Build the project",
                "build: src/main.c",
                "\tgcc -o build src/main.c",
                "",
                "## Remove build artifacts",
                "clean:",
                "\trm -f build",
            }, "\n")
        )

        require("makefile-targets").config.makefile_name = "Makefile"
        vim.api.nvim_buf_set_name(0, dir .. "/fake.c")
        require("makefile-targets.core").pick_target()

        local build = find_target(captured, "build")
        local clean = find_target(captured, "clean")

        assert.is_not_nil(build)
        assert.are.equal("Build the project", build and build.desc)
        assert.is_not_nil(clean)
        assert.are.equal("Remove build artifacts", clean and clean.desc)
    end)

    it("leaves desc nil when no comment is above the target", function()
        local _, dir = write_tmp(
            "Makefile",
            table.concat({
                "build: src/main.c",
                "\tgcc -o build src/main.c",
            }, "\n")
        )

        require("makefile-targets").config.makefile_name = "Makefile"
        vim.api.nvim_buf_set_name(0, dir .. "/fake.c")
        require("makefile-targets.core").pick_target()

        local build = find_target(captured, "build")
        assert.is_not_nil(build)
        assert.is_nil(build and build.desc)
    end)

    it("respects a custom desc_prefix", function()
        local _, dir = write_tmp(
            "Makefile",
            table.concat({
                "# Deploy to production",
                "deploy:",
                "\t./deploy.sh",
            }, "\n")
        )

        package.loaded["makefile-targets"] = nil
        package.loaded["makefile-targets.core"] = nil
        require("makefile-targets").setup({ finders = { "buffer" }, desc_prefix = "#" })
        vim.api.nvim_buf_set_name(0, dir .. "/fake.c")
        require("makefile-targets.core").pick_target()

        local deploy = find_target(captured, "deploy")
        assert.is_not_nil(deploy)
        assert.are.equal("Deploy to production", deploy and deploy.desc)
    end)

    it("does not use a ## comment that is not immediately above the target", function()
        local _, dir = write_tmp(
            "Makefile",
            table.concat({
                "## This is not adjacent",
                "",
                "build:",
                "\tgcc -o build src/main.c",
            }, "\n")
        )

        require("makefile-targets").config.makefile_name = "Makefile"
        vim.api.nvim_buf_set_name(0, dir .. "/fake.c")
        require("makefile-targets.core").pick_target()

        local build = find_target(captured, "build")
        assert.is_not_nil(build)
        assert.is_nil(build and build.desc)
    end)
end)

describe("get_search_root() git fallback", function()
    local captured
    local orig_vim_system

    before_each(function()
        captured = nil
        orig_vim_system = vim.system
        package.loaded["makefile-targets"] = nil
        package.loaded["makefile-targets.core"] = nil
        require("makefile-targets").setup({ finders = { "git", "buffer" } })
        ---@diagnostic disable-next-line: duplicate-set-field
        vim.ui.select = function(items, _, _)
            captured = items
        end
        ---@diagnostic disable-next-line: duplicate-set-field
        vim.notify = function(_, _) end
    end)

    after_each(function()
        vim.system = orig_vim_system
        vim.ui.select = nil
        vim.notify = nil
    end)

    it("uses the git root when git rev-parse succeeds", function()
        local _, git_root = write_tmp("Makefile", "build:\n\techo build\n")

        ---@diagnostic disable-next-line: duplicate-set-field
        vim.system = function(cmd, _opts)
            if cmd[1] == "git" then
                return {
                    wait = function()
                        return { code = 0, stdout = git_root .. "\n" }
                    end,
                }
            end
            return orig_vim_system(cmd, _opts)
        end

        -- Buffer is somewhere unrelated — root must come from git stub
        vim.api.nvim_buf_set_name(0, "/tmp/unrelated/fake.c")
        require("makefile-targets").config.makefile_name = "Makefile"
        require("makefile-targets.core").pick_target()

        assert.is_truthy(vim.tbl_contains(targets(captured), "build"))
    end)

    it("falls back to buffer dir when git rev-parse fails", function()
        local _, buf_dir = write_tmp("Makefile", "deploy:\n\techo deploy\n")

        ---@diagnostic disable-next-line: duplicate-set-field
        vim.system = function(cmd, _opts)
            if cmd[1] == "git" then
                return {
                    wait = function()
                        return { code = 128, stdout = "" }
                    end,
                }
            end
            return orig_vim_system(cmd, _opts)
        end

        vim.api.nvim_buf_set_name(0, buf_dir .. "/fake.c")
        require("makefile-targets").config.makefile_name = "Makefile"
        require("makefile-targets.core").pick_target()

        assert.is_truthy(vim.tbl_contains(targets(captured), "deploy"))
    end)
end)

describe("finders config", function()
    local captured
    local orig_vim_system

    local orig_cwd

    before_each(function()
        captured = nil
        orig_vim_system = vim.system
        orig_cwd = vim.fn.getcwd()
        ---@diagnostic disable-next-line: duplicate-set-field
        vim.ui.select = function(items, _, _)
            captured = items
        end
        ---@diagnostic disable-next-line: duplicate-set-field
        vim.notify = function(_, _) end
        -- Reset modules so config changes take effect cleanly
        package.loaded["makefile-targets"] = nil
        package.loaded["makefile-targets.core"] = nil
    end)

    after_each(function()
        vim.system = orig_vim_system
        vim.ui.select = nil
        vim.notify = nil
        vim.cmd("cd " .. orig_cwd)
    end)

    it("respects a custom finder order", function()
        local _, git_root = write_tmp("Makefile", "from-git:\n\techo git\n")
        local _, buffer_root = write_tmp("Makefile", "from-buffer:\n\techo buffer\n")

        ---@diagnostic disable-next-line: duplicate-set-field
        vim.system = function(cmd, _opts)
            if cmd[1] == "git" then
                return {
                    wait = function()
                        return { code = 0, stdout = git_root .. "\n" }
                    end,
                }
            end
            return orig_vim_system(cmd, _opts)
        end

        -- buffer finder should win because it's listed first
        vim.api.nvim_buf_set_name(0, buffer_root .. "/fake.c")
        require("makefile-targets").setup({ finders = { "buffer", "git" } })
        require("makefile-targets.core").pick_target()

        assert.is_truthy(vim.tbl_contains(targets(captured), "from-buffer"))
        assert.is_false(vim.tbl_contains(targets(captured), "from-git"))
    end)

    it("skips disabled finders", function()
        ---@diagnostic disable-next-line: duplicate-set-field
        vim.system = function(cmd, _opts)
            if cmd[1] == "git" then
                return {
                    wait = function()
                        return { code = 0, stdout = "/some/git/root\n" }
                    end,
                }
            end
            return orig_vim_system(cmd, _opts)
        end

        local warned = false
        ---@diagnostic disable-next-line: duplicate-set-field
        vim.notify = function(_, level)
            if level == vim.log.levels.WARN then
                warned = true
            end
        end

        -- Use an empty temp dir as cwd so there's definitely no Makefile there
        local empty_dir = vim.fn.tempname()
        vim.fn.mkdir(empty_dir, "pF")
        vim.api.nvim_buf_set_name(0, empty_dir .. "/fake.c")
        vim.cmd("cd " .. empty_dir)

        require("makefile-targets").setup({ finders = { "cwd" } })
        require("makefile-targets.core").pick_target()

        assert.is_true(warned)
        assert.is_nil(captured)
    end)

    it("warns on an unknown finder name", function()
        local warned_unknown = false
        ---@diagnostic disable-next-line: duplicate-set-field
        vim.notify = function(msg, _)
            if msg:find("Unknown finder") then
                warned_unknown = true
            end
        end

        require("makefile-targets").setup({ finders = { "nonexistent" } })
        require("makefile-targets.core").pick_target()

        assert.is_true(warned_unknown)
    end)
end)
