#!/usr/bin/env bash
# Module 05: Qualys integration helper.
set -euo pipefail

# shellcheck source=lib/common.sh
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)/lib/common.sh"

log "[QUALYS] Integration helper"

ensure_dir "$HOME/.config/beoniomarchy"

write_file "$BEONI_BIN_DIR/beoni-qualys" <<'EOF'
#!/usr/bin/env bash
# Qualys API helper for BeOniomarchy.
#
# Credentials are read from ~/.config/beoniomarchy/qualys.env (see the
# .env.example next to it) or from the environment:
#   QUALYS_USER   Qualys API username
#   QUALYS_PASS   Qualys API password
#   QUALYS_HOST   API host, default qualysapi.qualys.com
set -euo pipefail

ENV_FILE="${QUALYS_ENV:-$HOME/.config/beoniomarchy/qualys.env}"
if [ -f "$ENV_FILE" ]; then
  # shellcheck disable=SC1090
  . "$ENV_FILE"
fi

QUALYS_HOST="${QUALYS_HOST:-qualysapi.qualys.com}"
QUALYS_BASE="https://$QUALYS_HOST"

usage() {
  cat <<USAGE
Usage: beoni-qualys <command> [args]

Commands:
  hosts          List all tracked IPs of all asset groups
  ip <addr>      Show the asset record for one IP
  raw <path>     GET an arbitrary Qualys API path (e.g. /api/2.0/fo/asset/host/)
  help           Show this help

Configuration: $ENV_FILE
  QUALYS_USER=... QUALYS_PASS=... [QUALYS_HOST=qualysapi.qualys.com]
USAGE
}

qualys_get() {
  curl -sS --fail-with-body -u "$QUALYS_USER:$QUALYS_PASS" \
    -H "Content-Type: application/xml" \
    -G "$QUALYS_BASE$1" "${@:2}"
}

cmd="${1:-help}"
case "$cmd" in
  help | -h | --help)
    usage
    ;;
  hosts | ip | raw)
    if [ -z "${QUALYS_USER:-}" ] || [ -z "${QUALYS_PASS:-}" ]; then
      echo "qualys credentials missing - create $ENV_FILE from the .env.example" >&2
      exit 2
    fi
    case "$cmd" in
      hosts)
        qualys_get "/api/2.0/fo/asset/host/" --data-urlencode "action=list"
        ;;
      ip)
        [ $# -ge 2 ] || { echo "usage: beoni-qualys ip <addr>" >&2; exit 2; }
        qualys_get "/api/2.0/fo/asset/ip/" --data-urlencode "action=list" --data-urlencode "ips=$2"
        ;;
      raw)
        [ $# -ge 2 ] || { echo "usage: beoni-qualys raw <path>" >&2; exit 2; }
        qualys_get "$2" "${@:3}"
        ;;
    esac
    echo
    ;;
  *)
    echo "unknown command: $cmd" >&2
    usage >&2
    exit 2
    ;;
esac
EOF
write_file "$HOME/.config/beoniomarchy/qualys.env.example" 644 <<'EOF'
# Qualys credentials for beoni-qualys. Copy to qualys.env and fill in.
QUALYS_USER=your-api-user
QUALYS_PASS=your-api-password
# QUALYS_HOST=qualysapi.qualys.com
EOF
