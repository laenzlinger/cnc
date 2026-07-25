UGS_CONFIG_DIR = $(HOME)/.config/ugs
UGS_SOURCE_DIR = $(CURDIR)/ugs

.PHONY: help setup ugs stop-ugs check-ugs clean

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

stop-ugs: ## Stop UGS if running
	@if pidof -q ugsplatform 2>/dev/null || pgrep -f "[u]gsplatform" > /dev/null 2>&1; then \
		pkill -f "[u]gsplatform"; \
		sleep 2; \
		if pgrep -f "[u]gsplatform" > /dev/null 2>&1; then \
			pkill -9 -f "[u]gsplatform"; \
			sleep 1; \
		fi; \
		echo "✓ UGS stopped"; \
	else \
		echo "✓ UGS not running"; \
	fi

check-ugs: ## Fail if UGS is running (use before editing config)
	@if pgrep -f "[u]gsplatform" > /dev/null 2>&1; then \
		echo "✗ UGS is running. Config changes will be overwritten on exit."; \
		echo "  Run 'make stop-ugs' first."; \
		exit 1; \
	else \
		echo "✓ UGS not running, safe to edit config"; \
	fi

clean: ## Remove UGS config symlink
	@if [ -L "$(UGS_CONFIG_DIR)" ]; then \
		rm "$(UGS_CONFIG_DIR)"; \
		echo "✓ Removed $(UGS_CONFIG_DIR)"; \
	else \
		echo "Nothing to clean"; \
	fi

help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'
