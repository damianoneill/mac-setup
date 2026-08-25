SHELL := /bin/bash
SCRIPT := install.sh

.DEFAULT_GOAL := check

.PHONY: help lint fmt fmt-check check

help:
	@echo "Targets:"
	@echo "  lint       Run shellcheck on $(SCRIPT)"
	@echo "  fmt        Format $(SCRIPT) in place with shfmt"
	@echo "  fmt-check  Check $(SCRIPT) formatting without modifying it"
	@echo "  check      Run lint + fmt-check (default)"

lint:
	shellcheck $(SCRIPT)

fmt:
	shfmt -w -i 2 -ci $(SCRIPT)

fmt-check:
	shfmt -d -i 2 -ci $(SCRIPT)

check: lint fmt-check
