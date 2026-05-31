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
	@echo "                     Example: make stow-with-target TOOL_PATH=\"ai/cursor/tech-team\" TARGET_NAME=\".cursor\""
	@echo "  unstow      - Remove symlinks created by stow. Use CONFIGS to specify specific tools."
	@echo "                Example: make unstow CONFIGS=\"git ssh nvim\""
	@echo "  clean       - Clean up broken symlinks in the home directory"
	@echo "  bootstrap_local - Scaffold ~/dotfiles-local (or LOCAL_DIR=...) for per-host overrides"
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

.PHONY: bootstrap_local
bootstrap_local: prep ## Scaffold second stow tree (LOCAL_DIR=..., SKIP_GIT_INIT=1 optional)
	@DOTMATE_CANONICAL_ROOT=$(MAKEFILE_DIR) $(SCRIPT) bootstrap_local $(LOCAL_DIR)

# Brain memory / G2 audit targets (P3c)
BRAIN_SLUG ?= dotfiles
BRAIN_FIXTURE := $(MAKEFILE_DIR)/ai/ai-brain/projects/dotfiles/observability/fixtures/brain-audit-join-sample.jsonl
BRAIN_LEDGER ?= $(HOME)/ai-brain/projects/$(BRAIN_SLUG)/.meta/brain-audit-log.jsonl
BRAIN_SCRIPTS := $(MAKEFILE_DIR)/ai/ai-brain/scripts

.PHONY: check-brain-contract
check-brain-contract: ## Assert memory-demotion contract (source + materialized runtime)
	@chmod +x $(BRAIN_SCRIPTS)/check-memory-demotion-contract.sh
	@$(BRAIN_SCRIPTS)/check-memory-demotion-contract.sh

.PHONY: validate-brain-audit
validate-brain-audit: ## jq join on fixture; optional LEDGER= for live ledger
	@chmod +x $(BRAIN_SCRIPTS)/validate-brain-audit-join.sh
	@$(BRAIN_SCRIPTS)/validate-brain-audit-join.sh --fixture $(BRAIN_FIXTURE) \
		$(if $(LEDGER),--ledger $(LEDGER),)

.PHONY: check-g2-ready
check-g2-ready: ## G2 gate: live ledger must have joinable task_id groups
	@chmod +x $(BRAIN_SCRIPTS)/validate-brain-audit-join.sh
	@$(BRAIN_SCRIPTS)/validate-brain-audit-join.sh --ledger $(or $(LEDGER),$(BRAIN_LEDGER)) --ledger-only

.PHONY: materialize-brain-policy
materialize-brain-policy: ## Dry-run copy of memory-demotion.yml into ~/ai-brain
	@chmod +x $(BRAIN_SCRIPTS)/materialize-brain-policy.sh
	@$(BRAIN_SCRIPTS)/materialize-brain-policy.sh --dry-run

.PHONY: brain-migrate-dry-run
brain-migrate-dry-run: ## Frontmatter migration dry-run (P3a script)
	@chmod +x $(BRAIN_SCRIPTS)/migrate-brain-frontmatter.sh
	@$(BRAIN_SCRIPTS)/migrate-brain-frontmatter.sh --dry-run --slug $(BRAIN_SLUG)

.PHONY: brain-rebuild-l1
brain-rebuild-l1: ## Rebuild project L1 _index.md (P3a script)
	@chmod +x $(BRAIN_SCRIPTS)/brain-rebuild-l1-index.sh
	@$(BRAIN_SCRIPTS)/brain-rebuild-l1-index.sh --slug $(BRAIN_SLUG)

.PHONY: brain-sync-home
brain-sync-home: ## Regenerate ~/ai-brain/Home.md from projects (P4b)
	@chmod +x $(BRAIN_SCRIPTS)/brain-sync-home.sh
	@$(BRAIN_SCRIPTS)/brain-sync-home.sh --apply

.PHONY: brain-audit-synthetic
brain-audit-synthetic: ## Append synthetic kb_query+kb_demote episode to live ledger
	@chmod +x $(BRAIN_SCRIPTS)/brain-audit-synthetic-episode.sh
	@$(BRAIN_SCRIPTS)/brain-audit-synthetic-episode.sh --slug $(BRAIN_SLUG) \
		$(if $(LEDGER),--ledger $(LEDGER),) \
		$(if $(TASK_ID),--task-id $(TASK_ID),) \
		$(if $(TRACE_ID),--trace-id $(TRACE_ID),)

.PHONY: brain-efficiency-rollup
brain-efficiency-rollup: ## Append 7d SLO proxy row to brain-efficiency-audit.md
	@chmod +x $(BRAIN_SCRIPTS)/brain-efficiency-audit-rollup.sh
	@$(BRAIN_SCRIPTS)/brain-efficiency-audit-rollup.sh
