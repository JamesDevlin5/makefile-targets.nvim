.PHONY: format

FORMATTER_PATH := stylua
FORMATTER_ARGS := --config-path stylua.toml

# Format all Lua files using the project StyLua config.
format:
	$(FORMATTER_PATH) $(FORMATTER_ARGS) .
