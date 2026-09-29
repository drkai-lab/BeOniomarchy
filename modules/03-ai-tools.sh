#!/usr/bin/env bash
# Module 03: AI tooling.
set -euo pipefail

# shellcheck source=lib/common.sh
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)/lib/common.sh"

log "[AI] Preparing AI tools"

pkg_add uv ollama

if have_cmd ollama && ! systemctl is-enabled ollama >/dev/null 2>&1; then
  warn "ollama daemon not enabled - run: sudo systemctl enable --now ollama"
fi

log "coding agents: omarchy default agent <name>  (omarchy agent --help)"
