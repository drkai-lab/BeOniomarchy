#!/usr/bin/env bash
# Module 00: base environment, directories, baseline packages, tool symlinks.
set -euo pipefail

# shellcheck source=lib/common.sh
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)/lib/common.sh"

log "[SYSTEM] Preparing system environment"

have_cmd omarchy || die "omarchy not found - BeOniomarchy targets Omarchy systems"
log "omarchy: $(omarchy version 2>/dev/null || echo 'version unknown')"

ensure_dir "$BEONI_STATE_HOME"
ensure_dir "$BEONI_DATA_HOME"
ensure_dir "$BEONI_BIN_DIR"

pkg_add git curl unzip jq

link_tool() {
  local tool="$1" dest="$BEONI_BIN_DIR/beoni-$1"
  if [ -L "$dest" ] && [ "$(readlink "$dest")" = "$BEONI_ROOT/tools/$tool" ]; then
    log "tool link present: $dest"
    return 0
  fi
  if [ -e "$dest" ] || [ -L "$dest" ]; then
    if ! state_has_record create "$dest"; then
      backup_file "$dest"
    fi
  fi
  if is_dry; then
    dry_log "ln -s $BEONI_ROOT/tools/$tool $dest"
    return 0
  fi
  ensure_dir "$(dirname "$dest")"
  ln -sfn "$BEONI_ROOT/tools/$tool" "$dest"
  state_add_fields create "$dest"
  ok "linked: $dest"
}

for tool in webaudit apiaudit reportgen; do
  link_tool "$tool"
done

case ":$PATH:" in
  *":$BEONI_BIN_DIR:"*) ok "$BEONI_BIN_DIR is on PATH" ;;
  *) warn "$BEONI_BIN_DIR is not on PATH - add: export PATH=\"\$HOME/.local/bin:\$PATH\"" ;;
esac
