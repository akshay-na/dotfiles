#!/usr/bin/env bash
# Manual reminder: paired edits across Cursor + Gemini content packs (OR-07 mitigation, lite).
# For enforced drift detection, run: make verify-gemini-manifest
set -euo pipefail
echo "Dual-pack checkpoint:"
echo "  - If you edited dotfiles/ai/cursor-content-team/** behavior, also touch"
echo "    dotfiles/ai/gemini-content-team/** OR document the exception in"
echo "    dotfiles/ai/gemini-content-team/docs/runbooks/cursor-only-exclusions.md"
echo "  - Enforced check: make verify-gemini-manifest [GEMINI_MANIFEST_BASE=<git-ref>]"
echo "  - Parity plan: dotfiles/.cursor/docs/plans/2026-05-10-gemini-content-team-parity.md"
exit 0
