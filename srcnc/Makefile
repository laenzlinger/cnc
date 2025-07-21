
export OPENSCADPATH=scad

run:
	openscad --enable=fast-csg scad/main.scad &

build:
	scad/NopSCADlib/scripts/make_all.py

help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

