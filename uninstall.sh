#!/usr/bin/env bash
#
# BeOniomarchy uninstaller - reverses everything install.sh recorded in
# the state file.
set -euo pipefail

cd -- "$(dirname -- "${BASH_SOURCE[0]}")"
BEONI_ROOT="$PWD"
export BEONI_ROOT

# shellcheck source=lib/common.sh
source "$BEONI_ROOT/lib/common.sh"

usage() {
  cat <<EOF
BeOniomarchy v$BEONI_VERSION uninstaller

Usage: ./uninstall.sh [options]

Options:
  -n, --dry-run        Show what would be removed, change nothing
  -y, --yes            Skip the confirmation prompt
      --list           Show the recorded state and exit
      --keep-packages  Do not remove installed packages
      --keep-theme     Do not restore the previous theme / remove the theme
      --purge          Also delete BeOniomarchy reports and data
  -h, --help           Show this help

Reverses the state recorded by install.sh:
  $BEONI_STATE_FILE
EOF
}

KEEP_PKGS=0
KEEP_THEME=0
PURGE=0
LIST_ONLY=0
while [ $# -gt 0 ]; do
  case "$1" in
    -n | --dry-run) BEONI_DRY_RUN=1 ;;
    -y | --yes) BEONI_YES=1 ;;
    --list) LIST_ONLY=1 ;;
    --keep-packages) KEEP_PKGS=1 ;;
    --keep-theme) KEEP_THEME=1 ;;
    --purge) PURGE=1 ;;
    -h | --help)
      usage
      exit 0
      ;;
    *)
      usage >&2
      die "unknown option: $1"
      ;;
  esac
  shift
done
export BEONI_DRY_RUN BEONI_YES

echo "BeOniomarchy removal helper v$BEONI_VERSION"
echo

if [ "$LIST_ONLY" = 1 ]; then
  if [ -f "$BEONI_STATE_FILE" ]; then
    cat "$BEONI_STATE_FILE"
  else
    log "no state recorded at $BEONI_STATE_FILE"
  fi
  exit 0
fi

if [ ! -f "$BEONI_STATE_FILE" ]; then
  if [ "$PURGE" = 1 ]; then
    run rm -rf "$BEONI_DATA_HOME"
    ok "purged $BEONI_DATA_HOME"
  fi
  log "nothing recorded - nothing to uninstall"
  exit 0
fi

THEME_PREV=()
THEME_FORKS=()
CREATES=()
BACKUPS=()
DIRS=()
PKGS=()
while IFS=$'\t' read -r kind a b _rest; do
  case "$kind" in
    theme) THEME_PREV+=("$a") ;;
    themefork) THEME_FORKS+=("$a") ;;
    create) CREATES+=("$a") ;;
    backup) BACKUPS+=("$a"$'\t'"$b") ;;
    dir) DIRS+=("$a") ;;
    pkg) PKGS+=("$a") ;;
    '' | '#') ;;
    *) warn "unknown state entry: $kind" ;;
  esac
done <"$BEONI_STATE_FILE"

REMOVE_PKGS=()
if [ "$KEEP_PKGS" = 0 ]; then
  for p in "${PKGS[@]}"; do
    if pkg_installed "$p"; then
      REMOVE_PKGS+=("$p")
    fi
  done
fi

log "recorded state:"
printf '  theme restore:  %s\n' "${#THEME_PREV[@]}"
printf '  theme forks:    %s\n' "${#THEME_FORKS[@]}"
printf '  files created:  %s\n' "${#CREATES[@]}"
printf '  backups:        %s\n' "${#BACKUPS[@]}"
printf '  directories:    %s\n' "${#DIRS[@]}"
printf '  packages:       %s\n' "${#REMOVE_PKGS[@]}"
echo

if is_dry; then
  log "dry run - nothing will be changed"
elif [ "$BEONI_YES" != 1 ]; then
  if [ ! -t 0 ]; then
    die "non-interactive shell: re-run with --yes"
  fi
  printf 'Proceed with removal? [y/N] '
  read -r reply || reply=""
  case "$reply" in
    y | Y | yes | YES) ;;
    *)
      log "aborted"
      exit 0
      ;;
  esac
fi

FAILURES=0
note_failure() {
  FAILURES=$((FAILURES + 1))
  warn "$1"
}

# 1. Put the previous theme back before the fork disappears.
if [ "$KEEP_THEME" = 0 ] && have_cmd omarchy; then
  current=$(omarchy theme current 2>/dev/null || true)
  current_lc="${current,,}"
  if [[ "$current_lc" == *oniomarchy* ]]; then
    if [ "${#THEME_PREV[@]}" -eq 0 ]; then
      warn "Oniomarchy is active but no previous theme was recorded - run: omarchy theme set <theme>"
    fi
    for prev in "${THEME_PREV[@]}"; do
      if is_dry; then
        dry_log "omarchy theme set $prev"
      elif omarchy theme set "$prev"; then
        ok "theme restored: $prev"
      else
        note_failure "could not restore theme '$prev'"
      fi
    done
  else
    log "current theme is '${current:-unknown}' - leaving it alone"
  fi
fi

# 2. Restore files we modified.
for entry in "${BACKUPS[@]}"; do
  src="${entry%%$'\t'*}"
  dest="${entry#*$'\t'}"
  case "$src" in
    "$HOME"/* | "$BEONI_STATE_HOME"/*) ;;
    *)
      note_failure "refusing to restore outside HOME: $src"
      continue
      ;;
  esac
  if [ ! -e "$dest" ]; then
    note_failure "backup missing: $dest"
    continue
  fi
  if is_dry; then
    dry_log "cp -a $dest $src"
  elif cp -a "$dest" "$src"; then
    ok "restored: $src"
  else
    note_failure "could not restore $src"
  fi
done

# 3. Remove files we created.
for p in "${CREATES[@]}"; do
  case "$p" in
    "$HOME"/*) ;;
    *)
      note_failure "refusing to delete outside HOME: $p"
      continue
      ;;
  esac
  if [ -e "$p" ] || [ -L "$p" ]; then
    if is_dry; then
      dry_log "rm -f $p"
    elif rm -f -- "$p"; then
      ok "removed: $p"
    else
      note_failure "could not remove $p"
    fi
  fi
done

# 4. Remove the theme fork.
if [ "$KEEP_THEME" = 0 ]; then
  for fork in "${THEME_FORKS[@]}"; do
    case "$fork" in
      "$HOME/.config/omarchy/themes/"*) ;;
      *)
        note_failure "refusing to delete unexpected theme path: $fork"
        continue
        ;;
    esac
    if [ -d "$fork" ]; then
      if is_dry; then
        dry_log "rm -rf $fork"
      elif rm -rf -- "$fork"; then
        ok "removed theme: $fork"
      else
        note_failure "could not remove $fork"
      fi
    fi
  done
fi

# 5. Remove directories we created, if they are empty.
for d in "${DIRS[@]}"; do
  case "$d" in
    "$HOME"/*) ;;
    *) continue ;;
  esac
  if [ -d "$d" ]; then
    if is_dry; then
      dry_log "rmdir $d (only if empty)"
    elif rmdir -- "$d" 2>/dev/null; then
      ok "removed directory: $d"
    else
      log "kept (not empty): $d"
    fi
  fi
done

# 6. Remove packages we installed.
if [ "${#REMOVE_PKGS[@]}" -gt 0 ]; then
  log "removing packages: ${REMOVE_PKGS[*]}"
  if is_dry; then
    dry_log "sudo pacman -Rns --noconfirm ${REMOVE_PKGS[*]}"
  elif sudo pacman -Rns --noconfirm "${REMOVE_PKGS[@]}"; then
    ok "packages removed"
  else
    note_failure "package removal failed: ${REMOVE_PKGS[*]}"
  fi
fi

if [ "$FAILURES" -gt 0 ]; then
  warn "$FAILURES problem(s) occurred - state kept at $BEONI_STATE_FILE for a retry"
  exit 1
fi

if is_dry; then
  log "dry run finished - re-run without --dry-run to apply"
  exit 0
fi

rm -f "$BEONI_STATE_FILE"
rm -rf "$BEONI_STATE_HOME/backups"
if [ "$PURGE" = 1 ]; then
  rm -rf "$BEONI_DATA_HOME"
  ok "purged $BEONI_DATA_HOME"
fi
if [ -d "$BEONI_STATE_HOME" ]; then
  rmdir "$BEONI_STATE_HOME" 2>/dev/null || true
fi

echo
ok "BeOniomarchy removed"
if [ "$PURGE" = 0 ] && [ -d "$BEONI_DATA_HOME" ]; then
  log "reports kept in $BEONI_DATA_HOME (use --purge to delete them)"
fi
