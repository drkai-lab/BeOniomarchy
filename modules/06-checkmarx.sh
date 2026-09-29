#!/usr/bin/env bash
# Module 06: Checkmarx integration helper.
set -euo pipefail

# shellcheck source=lib/common.sh
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)/lib/common.sh"

log "[CHECKMARX] Integration helper"

ensure_dir "$HOME/.config/beoniomarchy"

write_file "$BEONI_BIN_DIR/beoni-checkmarx" <<'EOF'
#!/usr/bin/env bash
# Checkmarx API helper for BeOniomarchy - a thin authenticated curl wrapper.
#
# Credentials are read from ~/.config/beoniomarchy/checkmarx.env (see the
# .env.example next to it) or from the environment:
#   CX_TOKEN       API bearer token (required)
#   CX_BASE_URL    API base URL, default https://api.checkmarx.com
set -euo pipefail

ENV_FILE="${CX_ENV:-$HOME/.config/beoniomarchy/checkmarx.env}"
if [ -f "$ENV_FILE" ]; then
  # shellcheck disable=SC1090
  . "$ENV_FILE"
fi

CX_BASE_URL="${CX_BASE_URL:-https://api.checkmarx.com}"

usage() {
  cat <<USAGE
Usage: beoni-checkmarx <GET|POST|PUT|DELETE> <path> [json-body]

Examples:
  beoni-checkmarx GET  /projects
  beoni-checkmarx POST /projects '{"name":"demo"}'

Configuration: $ENV_FILE
  CX_TOKEN=... [CX_BASE_URL=https://api.checkmarx.com]
USAGE
}

cmd="${1:-help}"
case "$cmd" in
  help | -h | --help)
    usage
    ;;
  GET | POST | PUT | DELETE)
    if [ -z "${CX_TOKEN:-}" ]; then
      echo "CX_TOKEN missing - create $ENV_FILE from the .env.example" >&2
      exit 2
    fi
    [ $# -ge 2 ] || { echo "usage: beoni-checkmarx $cmd <path> [json]" >&2; exit 2; }
    args=(-sS --fail-with-body -X "$cmd"
      -H "Authorization: Bearer $CX_TOKEN"
      -H "Content-Type: application/json"
      -H "Accept: application/json")
    if [ -n "${3:-}" ]; then
      args+=(-d "$3")
    fi
    curl "${args[@]}" "$CX_BASE_URL$2"
    echo
    ;;
  *)
    echo "unknown command: $cmd" >&2
    usage >&2
    exit 2
    ;;
esac
EOF
write_file "$HOME/.config/beoniomarchy/checkmarx.env.example" 644 <<'EOF'
# Checkmarx credentials for beoni-checkmarx. Copy to checkmarx.env and fill in.
CX_TOKEN=your-api-token
# CX_BASE_URL=https://api.checkmarx.com
EOF
