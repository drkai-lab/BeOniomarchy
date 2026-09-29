#!/usr/bin/env bash
# Module 08: the Oniomarchy theme - forks a stock Omarchy theme under a new
# name with an oni-red palette and applies it.
set -euo pipefail

# shellcheck source=lib/common.sh
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)/lib/common.sh"

log "[THEME] Applying Oniomarchy theme"

STOCK="/usr/share/omarchy/themes/matte-black"
TARGET="$HOME/.config/omarchy/themes/$BEONI_THEME_SLUG"

have_cmd omarchy || die "omarchy not found"
[ -d "$STOCK" ] || die "stock theme not found: $STOCK"

if [ -d "$TARGET" ]; then
  log "theme already exists, keeping: $TARGET"
else
  if is_dry; then
    dry_log "fork $STOCK -> $TARGET"
  else
    state_add_fields themefork "$TARGET"
    ensure_dir "$(dirname "$TARGET")"
    cp -r "$STOCK" "$TARGET"
    rm -rf "$TARGET/.git"
    ok "forked theme: $TARGET"
    cat >"$TARGET/colors.toml" <<'TOML'
mode = "dark"

accent = "#ff4d5e"
selection = "#2a161a"
muted = "#3a2226"

background = "#121012"
dark_background = "#0d0b0d"
darker_background = "#090809"
lighter_background = "#1e181b"

foreground = "#e8dcdc"
dark_foreground = "#6b5a5c"
light_foreground = "#b3a0a2"
bright_foreground = "#f5eaea"

red = "#ff5f6d"
yellow = "#f5c542"
orange = "#ff8c42"
green = "#7ec98f"
cyan = "#6fd3d3"
blue = "#7aa2f7"
magenta = "#c678dd"
brown = "#8b3a3a"

bright_red = "#ff8a93"
bright_yellow = "#ffd97a"
bright_green = "#a5e6ae"
bright_cyan = "#9fe6e6"
bright_blue = "#a5c0ff"
bright_magenta = "#e0a5ff"
TOML
    ok "wrote palette: $TARGET/colors.toml"
  fi
fi

if [ "$BEONI_DRY_RUN" = 1 ]; then
  dry_log "omarchy theme set $BEONI_THEME_SLUG"
  exit 0
fi

prev=$(omarchy theme current 2>/dev/null || true)
prev_lc="${prev,,}"
if [ -n "$prev" ] && [[ "$prev_lc" != *oniomarchy* ]]; then
  state_add_fields theme "$prev"
  log "previous theme recorded: $prev"
fi

if [[ "$prev_lc" == *oniomarchy* ]]; then
  log "Oniomarchy theme already active"
else
  omarchy theme set "$BEONI_THEME_SLUG" || die "failed to apply theme"
  ok "theme applied: Oniomarchy (previous: ${prev:-none})"
fi
