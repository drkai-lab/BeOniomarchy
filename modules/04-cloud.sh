#!/usr/bin/env bash
# Module 04: cloud tooling.
set -euo pipefail

# shellcheck source=lib/common.sh
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)/lib/common.sh"

log "[CLOUD] Preparing cloud tools"

pkg_add kubectl helm k9s terraform kustomize
