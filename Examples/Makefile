# Makefile for Example project
# This is a simple wrapper around build.sh for convenience
# Note: For custom simulators, use ./build.sh directly

.PHONY: help build clean run list release

# Default target
help:
	@echo "Usage: make [target]"
	@echo ""
	@echo "Targets:"
	@echo "  build    - Build for default simulator (iPhone 16 Pro)"
	@echo "  run      - Build and run on default simulator"
	@echo "  release  - Build release version"
	@echo "  clean    - Clean build directory"
	@echo "  list     - List available simulators"
	@echo "  list-booted - List booted simulators"
	@echo ""
	@echo "For custom simulator, use: ./script/build.sh run \"iPhone 16 Pro\""

# Build for simulator (Debug)
build:
	@./script/build.sh build

# Build and run
run:
	@./script/build.sh run

# Build release version
release:
	@./script/build.sh release

# Clean build directory
clean:
	@./script/build.sh clean

# List available simulators
list:
	@./script/build.sh list

# List booted simulators
list-booted:
	@./script/build.sh list-booted
