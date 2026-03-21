-- Tests for lua/makefile-targets/init.lua

local assert = require("luassert")

describe("setup()", function()
    before_each(function()
        package.loaded["makefile-targets"] = nil
    end)

    it("applies default config when called with no args", function()
        local plugin = require("makefile-targets")
        plugin.setup()

        assert.are.equal("Makefile", plugin.config.makefile_name)
        assert.are.equal("make", plugin.config.make_cmd)
        assert.are.equal("", plugin.config.make_args)
        assert.are.equal("##", plugin.config.desc_prefix)
    end)

    it("merges user options over defaults", function()
        local plugin = require("makefile-targets")
        plugin.setup({ makefile_name = "GNUmakefile" })

        assert.are.equal("GNUmakefile", plugin.config.makefile_name)
        assert.are.equal("make", plugin.config.make_cmd) -- default preserved
    end)

    it("overrides make_cmd", function()
        local plugin = require("makefile-targets")
        plugin.setup({ make_cmd = "gmake" })

        assert.are.equal("gmake", plugin.config.make_cmd)
    end)

    it("overrides make_args", function()
        local plugin = require("makefile-targets")
        plugin.setup({ make_args = "-j4" })

        assert.are.equal("-j4", plugin.config.make_args)
    end)

    it("overrides finders", function()
        local plugin = require("makefile-targets")
        plugin.setup({ finders = { "buffer", "cwd" } })

        assert.are.same({ "buffer", "cwd" }, plugin.config.finders)
    end)
end)
