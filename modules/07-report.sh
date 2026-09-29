#!/usr/bin/env bash
# Module 07: report generation.
set -euo pipefail

# shellcheck source=lib/common.sh
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)/lib/common.sh"

log "[REPORT] Report generator"

ensure_dir "$BEONI_DATA_HOME/reports"

out="$BEONI_DATA_HOME/reports/report-$(date +%Y%m%d-%H%M%S).md"
if is_dry; then
  dry_log "$BEONI_ROOT/tools/reportgen --output $out"
else
  "$BEONI_ROOT/tools/reportgen" --output "$out"
fi
