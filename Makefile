.PHONY: help test build run check clean

# Default target
help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-15s\033[0m %s\n", $$1, $$2}'

test: ## Run all tests with full summary
	zig build test --summary all

build: ## Build the project
	zig build

run: ## Build and run the example window
	zig build run

check: ## Compile-check the project (no executable output)
	zig build check

clean: ## Remove build artifacts
	rm -rf zig-out .zig-cache
