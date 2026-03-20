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

        assert.are.same({ "build", "clean", "test" }, captured)
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

        assert.is_false(vim.tbl_contains(captured or {}, ".PHONY"))
        assert.is_false(vim.tbl_contains(captured or {}, "CC"))
        assert.is_truthy(vim.tbl_contains(captured or {}, "all"))
        assert.is_truthy(vim.tbl_contains(captured or {}, "clean"))
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
