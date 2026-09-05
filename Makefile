#
# Task runners for this project's development lifecycle.
#

.PHONY: install help

help:
	@echo "Available targets:"
	@echo "  install  - Restore this repo's Pop!_OS / Cosmic desktop backups onto the current machine"
	@echo "  help     - Show this help message"

install:
	./run/install
