# makefile-targets.nvim

Pick and run `make` targets.

## Installation

**lazy.nvim**
```lua
{
    "JamesDevlin5/makefile-targets.nvim",
    keys = {
        {
            "<Leader>m",
            function() require("makefile-targets.core").pick_target({ make_args = "-j4" }) end,
            desc = "Make: pick target"
        },
    },
    ---@type MakefileTargetsOpts
    opts = {},
}
```

## Usage

| Method | Action |
|---|---|
| `<Leader>m` | Open the target picker |
| `:MakefileTargets` | Same, via command |

Selecting a target runs `make <target>` in a terminal split at the bottom of the screen. Targets with a `##` comment on the line above them will show their description in the picker.

```makefile
## Build the project
build: src/main.c
	gcc -o build src/main.c

## Remove build artifacts
clean:
	rm -f build
```

## Configuration

```lua
require("makefile-targets").setup({
    makefile_name  = "Makefile",
    desc_prefix    = "##",
    make_cmd       = "make",
    make_args      = "",
    finders        = { "lsp", "git", "buffer", "cwd" },
})
```

## Optional features

### Dry run keymap

Add a separate keymap that runs `make -n <target>` (prints commands without executing):

```lua
{
    "JamesDevlin5/makefile-targets.nvim",
    keys = {
        {
            "<Leader>m",
            function() require("makefile-targets.core").pick_target() end,
            desc = "Make: pick target"
        },
        {
            "<Leader>M",
            function() require("makefile-targets.core").pick_target({ make_args = "-n" }) end,
            desc = "Make: pick target (dry run)"
        },
    },
    ---@type MakefileTargetsOpts
    opts = {},
}
```

### Telescope picker

[telescope.nvim](https://github.com/nvim-telescope/telescope.nvim)
picker with `<C-d>` to toggle dry run mode inline:

```lua
{
    "JamesDevlin5/makefile-targets.nvim",
    dependencies = { "nvim-telescope/telescope.nvim" },
    keys = {
        {
            "<Leader>mt",
            function() require("makefile-targets.telescope").pick_target() end,
            desc = "Make: pick target (Telescope)"
        },
    },
    ---@type MakefileTargetsOpts
    opts = {},
}
```

| Key | Action |
|---|---|
| `<CR>` | Run the selected target |
| `<C-d>` | Toggle dry run mode |

### Mini.pick picker

A [mini.pick](https://github.com/echasnovski/mini.pick) picker with the same
`<C-d>` dry run toggle:

```lua
{
    "JamesDevlin5/makefile-targets.nvim",
    dependencies = { "echasnovski/mini.pick" },
    keys = {
        {
            "<Leader>mm",
            function() require("makefile-targets.mini").pick_target() end,
            desc = "Make: pick target (Mini.pick)"
        },
    },
    ---@type MakefileTargetsOpts
    opts = {},
}
```

| Key | Action |
|---|---|
| `<CR>` | Run the selected target |
| `<Tab>` | Toggle recipe preview |
| `<C-d>` | Toggle dry run mode |

You can also call either picker directly without a keymap:

```lua
require("makefile-targets.telescope").pick_target()
require("makefile-targets.mini").pick_target()
```

