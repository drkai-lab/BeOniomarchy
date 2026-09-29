#!/usr/bin/env bash
#
# BeOniomarchy installer - turns an Omarchy system into an "Oniomarchy"
# security and development workstation.
set -euo pipefail

cd -- "$(dirname -- "${BASH_SOURCE[0]}")"
BEONI_ROOT="$PWD"
export BEONI_ROOT

# shellcheck source=lib/common.sh
source "$BEONI_ROOT/lib/common.sh"

usage() {
  cat <<EOF
BeOniomarchy v$BEONI_VERSION installer

Usage: ./install.sh [options]

Options:
  -n, --dry-run       Show what would be done, change nothing
  -y, --yes           Skip the confirmation prompt
      --only <list>   Run only these modules (comma separated numbers or names,
                      e.g. --only 01,theme)
      --list          List available modules and exit
  -h, --help          Show this help

The installer records every change in
  $BEONI_STATE_FILE
so ./uninstall.sh can reverse it.
EOF
}

print_modules() {
  local f
  for f in "$BEONI_ROOT"/modules/*.sh; do
    printf '  %s\n' "$(basename "$f" .sh)"
  done
}

ONLY=""
while [ $# -gt 0 ]; do
  case "$1" in
    -n | --dry-run) BEONI_DRY_RUN=1 ;;
    -y | --yes) BEONI_YES=1 ;;
    --only)
      [ $# -ge 2 ] || die "--only needs a value"
      ONLY="$2"
      shift
      ;;
    --only=*) ONLY="${1#--only=}" ;;
    --list)
      print_modules
      exit 0
      ;;
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
export BEONI_DRY_RUN BEONI_YES BEONI_RUN_ID

cat <<'BANNER'
 ____        ___        _
| __ )  ___ / _ \ _ __ (_)
|  _ \ / _ \ | | | '_ \|
| |_) |  __/ |_| | | | |
|____/ \___|\___/|_| |_|
BANNER
echo "BeOniomarchy v$BEONI_VERSION - Omarchy -> Oniomarchy workstation setup"
echo

shopt -s nullglob
ALL_MODULES=("$BEONI_ROOT"/modules/*.sh)
shopt -u nullglob
if [ "${#ALL_MODULES[@]}" -eq 0 ]; then
  die "no modules found in $BEONI_ROOT/modules"
fi

MODULES=()
if [ -n "$ONLY" ]; then
  declare -A seen=()
  IFS=',' read -ra wanted <<<"$ONLY"
  for w in "${wanted[@]}"; do
    w="${w%.sh}"
    matched=0
    for f in "${ALL_MODULES[@]}"; do
      base=$(basename "$f" .sh)
      if [ "$base" = "$w" ] || [[ "$base" == "$w"* ]] || [[ "$base" == *"-$w" ]]; then
        matched=1
        if [ -z "${seen[$f]:-}" ]; then
          MODULES+=("$f")
          seen[$f]=1
        fi
      fi
    done
    [ "$matched" -eq 1 ] || die "no module matches '$w' (see --list)"
  done
else
  MODULES=("${ALL_MODULES[@]}")
fi

have_cmd pacman || warn "pacman not found - this does not look like an Arch system"
if ! have_cmd omarchy; then
  if is_dry; then
    warn "omarchy not found - dry run only, install would stop here"
  else
    die "omarchy not found - BeOniomarchy targets Omarchy (https://omarchy.org)"
  fi
fi

log "modules to run:"
for f in "${MODULES[@]}"; do
  printf '  - %s\n' "$(basename "$f" .sh)"
done

if is_dry; then
  log "dry run - nothing will be changed"
elif [ "$BEONI_YES" != 1 ]; then
  if [ ! -t 0 ]; then
    die "non-interactive shell: re-run with --yes"
  fi
  printf 'Proceed with installation? [y/N] '
  read -r reply || reply=""
  case "$reply" in
    y | Y | yes | YES) ;;
    *)
      log "aborted"
      exit 0
      ;;
  esac
fi
echo

CURRENT_MODULE=""
trap 'warn "install failed in module: $CURRENT_MODULE"' ERR
for f in "${MODULES[@]}"; do
  CURRENT_MODULE=$(basename "$f")
  log "module: $CURRENT_MODULE"
  bash "$f"
done
trap - ERR

echo
ok "installation complete"
if is_dry; then
  log "dry run finished - re-run without --dry-run to apply"
  exit 0
fi

pkgs=$(awk -F'\t' '$1 == "pkg" { c++ } END { print c + 0 }' "$BEONI_STATE_FILE")
files=$(awk -F'\t' '$1 == "create" { c++ } END { print c + 0 }' "$BEONI_STATE_FILE")
log "tracked changes: $pkgs package(s), $files file(s)"
log "state: $BEONI_STATE_FILE"
log "undo everything with: ./uninstall.sh"
case ":$PATH:" in
  *":$BEONI_BIN_DIR:"*) ;;
  *) warn "$BEONI_BIN_DIR is not on PATH - add it to use the beoni-* tools" ;;
esac
