# makefile-targets.nvim

Pick and run `make` targets.

## Installation

**lazy.nvim**
```lua
{
  "JamesDevlin5/makefile-targets.nvim",
  config = function()
    require("makefile-targets").setup()
  end,
}
```

## Usage

| Method | Action |
|---|---|
| `<leader>m` (default) | Open the target picker |
| `:MakefileTargets` | Same, via command |

Selecting a target runs `make <target>`.

## Configuration

```lua
require("makefile-targets").setup({
  keymap        = "<leader>m",  -- false to disable
  makefile_name = "Makefile",   -- looked up relative to cwd
})
```

