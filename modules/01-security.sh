#!/usr/bin/env bash
# Module 01: security tooling.
set -euo pipefail

# shellcheck source=lib/common.sh
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)/lib/common.sh"

log "[SECURITY] Preparing security tools"

pkg_add nmap lynis clamav yara

write_file "$BEONI_BIN_DIR/beoni-audit" <<'EOF'
#!/usr/bin/env bash
# BeOniomarchy quick local security audit.
#   beoni-audit          port scan + listening sockets
#   beoni-audit --lynis  also run a full lynis audit (needs sudo)
set -euo pipefail

echo "== BeOniomarchy audit $(date -Is) on $(hostname) =="

if command -v nmap >/dev/null 2>&1; then
  echo
  echo "--- nmap 127.0.0.1 ---"
  nmap -sV -T4 127.0.0.1
fi

if command -v ss >/dev/null 2>&1; then
  echo
  echo "--- listening sockets ---"
  ss -tulpn
fi

if [ "${1:-}" = "--lynis" ] && command -v lynis >/dev/null 2>&1; then
  echo
  sudo lynis audit system --quick
elif [ "${1:-}" = "--lynis" ]; then
  echo "lynis is not installed" >&2
  exit 1
fi
EOF
if have_cmd docker; then
  if id -nG "${USER:-$(id -un)}" | tr ' ' '\n' | grep -Fxq docker; then
    ok "user already in docker group"
  else
    warn "docker installed but you are not in the docker group: sudo usermod -aG docker \"\$USER\" (re-login needed)"
  fi
fi
