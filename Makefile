# Dotfiles Makefile — convenience entry points
# Assumes GNU make.

DOTFILES := $(shell pwd)
SCRIPTS  := $(DOTFILES)/scripts

.PHONY: all link install update help

all: help

## install   — install packages then link configs (full first-time setup)
install:
	@bash $(SCRIPTS)/install-packages.sh
	@bash $(SCRIPTS)/link-configs.sh

## link      — symlink configs only (no package install)
link:
	@bash $(SCRIPTS)/link-configs.sh

## update    — pull latest dotfiles and re-link
update:
	@git -C $(DOTFILES) pull --ff-only
	@bash $(SCRIPTS)/link-configs.sh

## bootstrap — full one-shot setup including package install + optional SSH key
bootstrap:
	@bash $(SCRIPTS)/bootstrap.sh

## help      — show this help
help:
	@echo ""
	@echo "  Dotfiles targets:"
	@echo ""
	@grep -E '^## ' $(MAKEFILE_LIST) | sed 's/## /    make /'
	@echo ""
