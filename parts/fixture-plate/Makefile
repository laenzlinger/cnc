.DEFAULT_GOAL := help

all: fixture-plate.stl fixture-plate.nc ## generate all outputs

fixture-plate.stl: fixture-plate.scad ## generate STL
	openscad -o fixture-plate.stl fixture-plate.scad

fixture-plate.nc: fixture-plate-gcode.py ## generate G-code
	python3 fixture-plate-gcode.py > fixture-plate.nc

help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'
