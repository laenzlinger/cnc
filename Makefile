UGS_CONFIG_DIR = $(HOME)/.config/ugs
UGS_SOURCE_DIR = $(CURDIR)/ugs

.PHONY: help setup ugs clean

default: help

setup: ## Symlink UGS config to ~/.config/ugs
	@if [ -L "$(UGS_CONFIG_DIR)" ] && [ "$$(readlink "$(UGS_CONFIG_DIR)")" = "$(UGS_SOURCE_DIR)" ]; then \
		echo "✓ $(UGS_CONFIG_DIR) already symlinked correctly"; \
	elif [ -e "$(UGS_CONFIG_DIR)" ]; then \
		echo "$(UGS_CONFIG_DIR) already exists. Remove it first:"; \
		echo "  rm -rf $(UGS_CONFIG_DIR)"; \
		exit 1; \
	else \
		ln -s "$(UGS_SOURCE_DIR)" "$(UGS_CONFIG_DIR)"; \
		echo "✓ Created symlink: $(UGS_CONFIG_DIR) → $(UGS_SOURCE_DIR)"; \
	fi

ugs: ## Launch UGS
	@./ugs/ugs.sh

clean: ## Remove UGS config symlink
	@if [ -L "$(UGS_CONFIG_DIR)" ]; then \
		rm "$(UGS_CONFIG_DIR)"; \
		echo "✓ Removed $(UGS_CONFIG_DIR)"; \
	else \
		echo "Nothing to clean"; \
	fi

help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'
