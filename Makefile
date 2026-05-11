# Makefile for Dotfiles Management
# This Makefile provides an easy interface for managing dotfiles using the `DotMate.sh` script.

# Variables
SCRIPT := ./scripts/DotMate.sh
# Makefile directory (repo root even when invoked as `make -f path/Makefile`)
MAKEFILE_DIR := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))

# Colors for output
GREEN := \033[1;32m
YELLOW := \033[1;33m
RESET := \033[0m

# Ensure script is executable before running any target
.PHONY: prep
prep:
	@chmod +x $(SCRIPT)
	@if [ -d "./ssh/.ssh" ]; then \
		chmod 700 ./ssh/.ssh; \
		find ./ssh/.ssh -type f -exec chmod 600 {} \; 2>/dev/null; \
	fi
	@if [ -d "./ssh/.ssh/sockets" ]; then \
		find ./ssh/.ssh/sockets -type f -exec chmod 600 {} \; 2>/dev/null; \
	fi
	@if [ -d "./gnupg/.gnupg" ]; then \
		chmod 700 ./gnupg/.gnupg; \
		find ./gnupg/.gnupg -type f -exec chmod 600 {} \; 2>/dev/null; \
	fi

# Default target to show available commands and usage
.PHONY: help
help:
	@echo -e "${YELLOW}Usage: make <target> [CONFIGS=\"tool1 tool2 ...\"]${RESET}"
	@echo -e "${GREEN}Available targets:${RESET}"
	@echo "  backup      - Backup existing dotfiles"
	@echo "  update      - Check for updates in the dotfiles repository"
	@echo "  install     - Install necessary tools and set up environment"
	@echo "  stow        - Create symlinks for dotfiles using stow. Use CONFIGS to specify specific tools."
	@echo "                Example: make stow CONFIGS=\"git ssh nvim\""
	@echo "  stow-with-target - Stow one folder path to a custom target under HOME."
	@echo "                     Example: make stow-with-target TOOL_PATH=\"ai/cursor-tech-team\" TARGET_NAME=\".cursor\""
	@echo "  unstow      - Remove symlinks created by stow. Use CONFIGS to specify specific tools."
	@echo "                Example: make unstow CONFIGS=\"git ssh nvim\""
	@echo "  clean       - Clean up broken symlinks in the home directory"
	@echo "  bootstrap-local - Scaffold ~/dotfiles-local (or LOCAL_DIR=...) for per-host overrides"
	@echo "                Run from upstream clone; copies DotMate.sh, Makefile, .stowrc from canonical root."
	@echo "  help        - Show this help message"

# Targets

.PHONY: backup
backup: prep ## Backup existing dotfiles
	@$(SCRIPT) backup

.PHONY: update
update: prep ## Check for updates in the dotfiles repository
	@$(SCRIPT) update

.PHONY: install
install: prep ## Install tools and set up environment
	@$(SCRIPT) install

.PHONY: stow prep
stow: prep ## Create symlinks for specified dotfiles
	@$(SCRIPT) stow $(CONFIGS)

.PHONY: stow-with-target
stow-with-target: prep ## Stow one folder path to target folder name
	@$(SCRIPT) stow_with_target $(TOOL_PATH) $(TARGET_NAME)

.PHONY: unstow
unstow: prep ## Remove symlinks for specified dotfiles
	@$(SCRIPT) unstow $(CONFIGS)

.PHONY: clean
clean: prep ## Clean up broken symlinks
	@$(SCRIPT) clean

.PHONY: bootstrap-local
bootstrap-local: prep ## Scaffold second stow tree (LOCAL_DIR=..., SKIP_GIT_INIT=1 optional)
	@DOTMATE_CANONICAL_ROOT=$(MAKEFILE_DIR) $(SCRIPT) bootstrap_local $(LOCAL_DIR)
