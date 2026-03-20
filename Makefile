.PHONY: test format format-json

NVIM_PATH      := nvim
MINIMAL_INIT   := tests/minimal_init.lua

LUA_FORMATTER_PATH := stylua
LUA_FORMATTER_ARGS := --config-path stylua.toml

JSON_FORMATTER_PATH := python3 -m json.tool
JSON_FILES          := .releaserc

# Run the full test suite in a headless Neovim instance.
# Requires nvim to be on your PATH.
test:
	@$(NVIM_PATH) \
	  --headless \
	  --noplugin \
	  -u $(MINIMAL_INIT) \
	  -c "lua require('plenary.test_harness').test_directory('tests/', { minimal_init = '$(MINIMAL_INIT)' })"

# Format all Lua files using the project StyLua config.
format:
	@$(LUA_FORMATTER_PATH) $(LUA_FORMATTER_ARGS) .

JSON_EXTRA_ARGS := $(foreach f,$(JSON_FILES), -o -name "$(f)")

format-json:
	@for f in $(shell find . \( -name "*.json" $(JSON_EXTRA_ARGS) \) -not -path "./node_modules/*"); do \
		$(JSON_FORMATTER_PATH) "$$f" > "$$f.tmp" && mv "$$f.tmp" "$$f"; \
	done
