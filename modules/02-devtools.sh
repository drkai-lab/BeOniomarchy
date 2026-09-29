#!/usr/bin/env bash
# Module 02: developer tooling.
set -euo pipefail

# shellcheck source=lib/common.sh
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)/lib/common.sh"

log "[DEV] Preparing developer tools"

pkg_add lazygit ripgrep fzf bat eza jq docker docker-compose

if have_cmd docker && ! systemctl is-enabled docker >/dev/null 2>&1; then
  warn "docker daemon not enabled - run: sudo systemctl enable --now docker"
fi
