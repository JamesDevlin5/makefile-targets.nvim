.PHONY: test format

NVIM_PATH      := nvim
MINIMAL_INIT   := tests/minimal_init.lua

FORMATTER_PATH := stylua
FORMATTER_ARGS := --config-path stylua.toml

# Run the full test suite in a headless Neovim instance.
# Requires nvim to be on your PATH.
test:
	$(NVIM_PATH) \
	  --headless \
	  --noplugin \
	  -u $(MINIMAL_INIT) \
	  -c "lua require('plenary.test_harness').test_directory('tests/', { minimal_init = '$(MINIMAL_INIT)' })"

# Format all Lua files using the project StyLua config.
format:
	$(FORMATTER_PATH) $(FORMATTER_ARGS) .
