-- Tests for lua/makefile-targets/init.lua

local assert = require("luassert")

describe("setup()", function()
    before_each(function()
        -- Reset the module between tests so config changes don't bleed across
        package.loaded["makefile-targets"] = nil
    end)

    it("applies default config when called with no args", function()
        local plugin = require("makefile-targets")
        plugin.setup()

        assert.are.equal("<Leader>m", plugin.config.keymap)
        assert.are.equal("Makefile", plugin.config.makefile_name)
    end)

    it("merges user options over defaults", function()
        local plugin = require("makefile-targets")
        plugin.setup({ makefile_name = "GNUmakefile" })

        assert.are.equal("<Leader>m", plugin.config.keymap) -- default preserved
        assert.are.equal("GNUmakefile", plugin.config.makefile_name) -- override applied
    end)

    it("accepts keymap = false to skip keymap registration", function()
        local plugin = require("makefile-targets")

        -- If keymap=false causes an error during setup, this test will fail
        assert.has_no_error(function()
            plugin.setup({ keymap = false })
        end)

        assert.are.equal(false, plugin.config.keymap)
    end)

    it("registers a keymap when keymap is a string", function()
        local plugin = require("makefile-targets")
        plugin.setup({ keymap = "<leader>mk" })

        -- maparg accepts the unexpanded form and returns a non-empty table if the
        -- mapping exists; an unregistered lhs returns an empty table.
        local mapping = vim.fn.maparg("<leader>mk", "n", false, true)

        assert.is_true(type(mapping) == "table" and mapping.lhs ~= nil)
    end)

    it("registers a dry_run_keymap when dry_run_keymap is a string", function()
        local plugin = require("makefile-targets")
        plugin.setup({ dry_run_keymap = "<leader>mK" })

        local mapping = vim.fn.maparg("<leader>mK", "n", false, true)

        assert.is_true(type(mapping) == "table" and mapping.lhs ~= nil)
    end)

    it("accepts dry_run_keymap = false to skip registration", function()
        local plugin = require("makefile-targets")

        assert.has_no_error(function()
            plugin.setup({ dry_run_keymap = false })
        end)

        assert.are.equal(false, plugin.config.dry_run_keymap)
    end)

    it("applies default dry_run_keymap when called with no args", function()
        local plugin = require("makefile-targets")
        plugin.setup()

        assert.are.equal(false, plugin.config.dry_run_keymap)
    end)
end)
