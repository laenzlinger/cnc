
FLUIDDIAL_VERSION ?= v1.0.1
RELEASE = https://github.com/bdring/fluiddial-releases/raw/refs/heads/main/releases/$(FLUIDDIAL_VERSION)/cyddial.bin

.PHONY: help clean

default: help

download: ## download the latest FluidNC release
	@echo "Downloading FluidDIAL $(FLUIDNC_VERSION) from $(RELEASE)"
	@curl -L -o cyddial.bin $(RELEASE)

install: download ## install FluidDIAL
	@echo "Installing FluidDIAL $(FLUIDDIAL_VERSION)"
	esptool.py --baud 300000 --chip esp32 --port /dev/ttyUSB0 write_flash --flash_mode dio --flash_size detect 0x0 cyddial.bin

clean: ## clean temporary files
	rm -f cyddial.bin

help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

