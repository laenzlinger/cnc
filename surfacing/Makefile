.DEFAULT_GOAL := help

surfacing.nc: surfacing.py ## generate surfacing G-code
	python3 surfacing.py > surfacing.nc

help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'
