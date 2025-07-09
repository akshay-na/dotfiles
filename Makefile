# Makefile for Dotfiles Management
# This Makefile provides an easy interface for managing dotfiles using the `DotMate.sh` script.

# Variables
SCRIPT := ./scripts/DotMate.sh

# Colors for output
GREEN := \033[1;32m
YELLOW := \033[1;33m
RESET := \033[0m

# Ensure script is executable before running any target
.PHONY: prep
	@chmod +x $(SCRIPT)

	# SSH permissions
	@if [ -d "./ssh/.ssh" ]; then \
	    chmod 700 ./ssh/.ssh; \
	    find ./ssh/.ssh -type f -exec chmod 600 {} \; 2>/dev/null; \
	    echo "SSH permissions set."; \
	else \
	    echo "Warning: ./ssh/.ssh does not exist, skipping SSH permissions."; \
	fi

	# SSH socket permissions (only if directory exists)
	@if [ -d "./ssh/.ssh/sockets" ]; then \
	    find ./ssh/.ssh/sockets -type f -exec chmod 600 {} \; 2>/dev/null; \
	    echo "SSH socket permissions set."; \
	else \
	    echo "Warning: ./ssh/.ssh/sockets does not exist, skipping socket permissions."; \
	fi

	# GPG permissions
	@if [ -d "./gnupg/.gnupg" ]; then \
	    chmod 700 ./gnupg/.gnupg; \
	    chmod +x ./gnupg/.gnupg/pinentry.sh; \
	    find ./gnupg/.gnupg -type f -exec chmod 600 {} \; 2>/dev/null; \
	    echo "GPG permissions set."; \
	else \
	    echo "Warning: ./gnupg/.gnupg does not exist, skipping GPG permissions."; \
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
	@echo "  unstow      - Remove symlinks created by stow. Use CONFIGS to specify specific tools."
	@echo "                Example: make unstow CONFIGS=\"git ssh nvim\""
	@echo "  clean       - Clean up broken symlinks in the home directory"
	@echo "  help        - Show this help message"

# Targets

.PHONY: backup
backup: prep ## Backup existing dotfiles
	$(SCRIPT) backup

.PHONY: update
update: prep ## Check for updates in the dotfiles repository
	$(SCRIPT) update

.PHONY: install
install: prep ## Install tools and set up environment
	$(SCRIPT) install

.PHONY: stow prep
stow: prep ## Create symlinks for specified dotfiles
	@$(SCRIPT) stow $(CONFIGS)

.PHONY: unstow
unstow: prep ## Remove symlinks for specified dotfiles
	@$(SCRIPT) unstow $(CONFIGS)

.PHONY: clean
clean: prep ## Clean up broken symlinks
	$(SCRIPT) clean
