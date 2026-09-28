#
# Task runners for this project's development lifecycle.
#

.PHONY: export import help

help:
	@echo "Available targets:"
	@echo "  export   - Back up the current machine's Pop!_OS / Cosmic desktop config into this repo"
	@echo "  import   - Restore this repo's Pop!_OS / Cosmic desktop backups onto the current machine"
	@echo "  help     - Show this help message"

export:
	./run/export

import:
	./run/import
