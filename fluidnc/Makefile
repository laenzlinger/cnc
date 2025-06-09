
FLUIDNC_VERSION ?= v3.9.7
RELEASE = https://github.com/bdring/FluidNC/releases/download/$(FLUIDNC_VERSION)/fluidnc-$(FLUIDNC_VERSION)-posix.zip
CONFIG = SRcnc/config.yaml
FLUIDNC_FQDN = fluidnc.home

.PHONY: help clean

default: help

download: ## download the latest FluidNC release
	@echo "Downloading FluidNC $(FLUIDNC_VERSION) from $(RELEASE)"
	@curl -L -o fluidnc-$(FLUIDNC_VERSION)-posix.zip $(RELEASE)
	unzip -o fluidnc-$(FLUIDNC_VERSION)-posix.zip
	mv fluidnc-$(FLUIDNC_VERSION)-posix fluidnc
	rm fluidnc-$(FLUIDNC_VERSION)-posix.zip

clean: ## clean temporary files
	rm -f fluidnc-$(FLUIDNC_VERSION)-posix.zip
	rm -rf fluidnc

fluidterm: ## open terminal to fluidnc
	cd fluidnc && ./fluidterm.sh --echo /dev/cnc

upload-config-fd: ## install config uisng fluidterm
	@echo "Uploading config $(CONFIG) to FluidNC"
	# remove the following line once the PR is merged and released
	@cp ../../fluidnc/fluidterm/fluidterm.py fluidnc/common
	@cd fluidnc && ./fluidterm.sh --echo --upload $(PWD)/$(CONFIG) /dev/cnc

upload-config: ## install config using web API
	@echo "Uploading config to FluidNC"
	curl -F "file=@./$(CONFIG);filename=/config.yaml" http://$(FLUIDNC_FQDN)/files
	curl http://$(FLUIDNC_FQDN)/command?commandText=%18

web-socket: ## open web socket to FluidNC
	@echo "Opening web socket to FluidNC"
	websocat ws://$(FLUIDNC_FQDN):81 | grep -v "^PING:."

help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

