#!/usr/bin/env bash
# BeOniomarchy shared helpers.
# Sourced by install.sh, uninstall.sh and every module in modules/.
#
# State file format (TSV), one record per line:
#   pkg       <package>                       package installed by us
#   create    <path>                          file/symlink we created
#   backup    <source-path> <backup-path>     original file saved before we touched it
#   dir       <path>                          directory we created
#   theme     <previous-theme>                theme to restore on uninstall
#   themefork <path>                          theme directory we forked

if [ -n "${BEONI_COMMON_LOADED:-}" ]; then
  # Already loaded: stop when sourced, continue harmlessly when executed.
  # shellcheck disable=SC2317
  return 0 2>/dev/null || true
fi
BEONI_COMMON_LOADED=1

export BEONI_VERSION="1.0.0"
export BEONI_THEME_SLUG="oniomarchy"

: "${BEONI_ROOT:=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)}"
: "${BEONI_STATE_HOME:=${XDG_STATE_HOME:-$HOME/.local/state}/beoniomarchy}"
: "${BEONI_DATA_HOME:=${XDG_DATA_HOME:-$HOME/.local/share}/beoniomarchy}"
: "${BEONI_BIN_DIR:=$HOME/.local/bin}"
: "${BEONI_DRY_RUN:=0}"
: "${BEONI_YES:=0}"
: "${BEONI_RUN_ID:=$(date +%Y%m%d-%H%M%S)}"

BEONI_STATE_FILE="$BEONI_STATE_HOME/state.tsv"
BEONI_BACKUP_DIR="$BEONI_STATE_HOME/backups/$BEONI_RUN_ID"

if [ -t 1 ]; then
  C_RESET=$'\033[0m'
  C_RED=$'\033[31m'
  C_GREEN=$'\033[32m'
  C_YELLOW=$'\033[33m'
  C_BLUE=$'\033[34m'
  C_BOLD=$'\033[1m'
else
  C_RESET=''
  C_RED=''
  C_GREEN=''
  C_YELLOW=''
  C_BLUE=''
  C_BOLD=''
fi

log() { printf '%sinfo%s  %s\n' "$C_BLUE" "$C_RESET" "$*"; }
ok() { printf '%s ok %s  %s\n' "$C_GREEN" "$C_RESET" "$*"; }
warn() { printf '%swarn%s  %s\n' "$C_YELLOW" "$C_RESET" "$*" >&2; }
die() { printf '%sfail%s  %s\n' "$C_RED" "$C_RESET" "$*" >&2; exit 1; }

is_dry() { [ "${BEONI_DRY_RUN:-0}" = 1 ]; }
dry_log() {
  if is_dry; then
    printf '%sdry %s   %s\n' "$C_BOLD" "$C_RESET" "$*"
  fi
}
have_cmd() { command -v "$1" >/dev/null 2>&1; }

run() {
  if is_dry; then
    printf '%sdry %s   %s\n' "$C_BOLD" "$C_RESET" "$*"
    return 0
  fi
  "$@"
}

state_init() {
  mkdir -p "$BEONI_STATE_HOME" "$BEONI_BACKUP_DIR"
  [ -f "$BEONI_STATE_FILE" ] || : >"$BEONI_STATE_FILE"
}

state_has() {
  [ -f "$BEONI_STATE_FILE" ] && grep -Fxq -- "$1" "$BEONI_STATE_FILE"
}

# state_has_record <kind> <value> - true when a "kind\tvalue" record exists
state_has_record() {
  [ -f "$BEONI_STATE_FILE" ] &&
    awk -F'\t' -v k="$1" -v v="$2" '$1 == k && $2 == v { found = 1 } END { exit !found }' \
      "$BEONI_STATE_FILE"
}

state_add() {
  state_init
  if state_has "$1"; then
    return 0
  fi
  printf '%s\n' "$1" >>"$BEONI_STATE_FILE"
}

# state_add_fields <field>...  -> joins fields with tabs
state_add_fields() {
  local line
  printf -v line '%s\t' "$@"
  state_add "${line%$'\t'}"
}

pkg_installed() { pacman -Q -- "$1" >/dev/null 2>&1; }

pkg_add() {
  local p
  local need=()
  for p in "$@"; do
    if pkg_installed "$p"; then
      log "package already installed: $p"
    else
      need+=("$p")
    fi
  done
  if [ "${#need[@]}" -eq 0 ]; then
    return 0
  fi
  if is_dry; then
    dry_log "install packages: ${need[*]}"
    return 0
  fi
  if have_cmd omarchy; then
    if ! omarchy pkg add "${need[@]}"; then
      warn "omarchy pkg add failed; falling back to pacman"
      sudo pacman -S --needed --noconfirm "${need[@]}" || die "failed to install: ${need[*]}"
    fi
  else
    sudo pacman -S --needed --noconfirm "${need[@]}" || die "failed to install: ${need[*]}"
  fi
  for p in "${need[@]}"; do
    if pkg_installed "$p"; then
      state_add_fields pkg "$p"
      ok "installed package: $p"
    else
      warn "package not installed: $p"
    fi
  done
}

ensure_dir() {
  local d="$1"
  if [ -d "$d" ]; then
    return 0
  fi
  if is_dry; then
    dry_log "mkdir -p $d"
    return 0
  fi
  state_add_fields dir "$d"
  mkdir -p "$d"
  ok "created directory: $d"
}

# Save the original of $1 once; repeated runs never clobber the first backup.
backup_file() {
  local src="$1" dest existing
  if [ ! -e "$src" ] && [ ! -L "$src" ]; then
    return 0
  fi
  if [ -f "$BEONI_STATE_FILE" ]; then
    existing=$(awk -F'\t' -v s="$src" '$1 == "backup" && $2 == s { print $3; exit }' "$BEONI_STATE_FILE")
    if [ -n "$existing" ] && [ -e "$existing" ]; then
      log "original already backed up: $src"
      return 0
    fi
  fi
  dest="$BEONI_BACKUP_DIR$src"
  if is_dry; then
    dry_log "backup $src -> $dest"
    return 0
  fi
  state_add_fields backup "$src" "$dest"
  mkdir -p "$(dirname "$dest")"
  cp -a "$src" "$dest"
  ok "backed up: $src"
}

# install_file <source> <dest> [mode]  - backup dest if it exists, then copy
install_file() {
  local src="$1" dest="$2" mode="${3:-}" existed=0
  if [ -e "$dest" ] || [ -L "$dest" ]; then
    existed=1
    if ! state_has_record create "$dest"; then
      backup_file "$dest"
    fi
  fi
  if is_dry; then
    dry_log "write $dest"
    return 0
  fi
  ensure_dir "$(dirname "$dest")"
  cp -a "$src" "$dest"
  if [ -n "$mode" ]; then
    chmod "$mode" "$dest"
  fi
  if [ "$existed" -eq 0 ]; then
    state_add_fields create "$dest"
  fi
  ok "installed file: $dest"
}

# write_file <dest> [mode]  - reads the new file content from stdin (default mode 755)
write_file() {
  local dest="$1" mode="${2:-755}" tmp
  tmp=$(mktemp)
  cat >"$tmp"
  chmod "$mode" "$tmp"
  install_file "$tmp" "$dest"
  rm -f "$tmp"
}
