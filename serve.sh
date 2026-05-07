#!/usr/bin/env bash
# serve.sh - Prints every download oneliner, then serves tools/ over HTTP.
# Auto-detects tun0 IP. Falls back to tun1 / eth0 / first non-loopback.
#
# Usage:
#   ./serve.sh                 # default port 8000
#   ./serve.sh 80              # custom port (sudo if <1024)
#   ./serve.sh --no-banner     # skip the payload dump
set -u

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ARS="$ROOT/tools"

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; RED='\033[0;31m'; BOLD='\033[1m'; NC='\033[0m'

PORT=8000
SHOW_BANNER=1
for a in "$@"; do
    case "$a" in
        --no-banner) SHOW_BANNER=0 ;;
        ''|*[!0-9]*) ;;
        *) PORT="$a" ;;
    esac
done

if [ ! -d "$ARS" ]; then
    echo -e "${RED}[x]${NC} tools/ directory missing. Run first: ./build_arsenal.sh"
    exit 1
fi

detect_ip() {
    local ip
    ip=$(ip -4 addr show tun0 2>/dev/null | awk '/inet /{print $2}' | cut -d/ -f1 | head -1)
    [ -n "$ip" ] && { echo "$ip"; return; }
    ip=$(ip -4 addr show tun1 2>/dev/null | awk '/inet /{print $2}' | cut -d/ -f1 | head -1)
    [ -n "$ip" ] && { echo "$ip"; return; }
    ip=$(ip -4 addr show eth0 2>/dev/null | awk '/inet /{print $2}' | cut -d/ -f1 | head -1)
    [ -n "$ip" ] && { echo "$ip"; return; }
    ip=$(ifconfig 2>/dev/null | awk '/inet /{print $2}' | grep -v 127.0.0.1 | head -1)
    [ -n "$ip" ] && { echo "$ip"; return; }
    echo "0.0.0.0"
}

IP="$(detect_ip)"
export ARSENAL_IP="$IP"
export ARSENAL_PORT="$PORT"

clear 2>/dev/null || true

if [ "$SHOW_BANNER" -eq 1 ]; then
    cat <<EOF
${BOLD}${CYAN}
==============================================================
   OSCP ARSENAL  -  serving $ARS
==============================================================${NC}

${BOLD}IP   :${NC} ${GREEN}$IP${NC}
${BOLD}PORT :${NC} ${GREEN}$PORT${NC}
${BOLD}URL  :${NC} ${GREEN}http://$IP:$PORT/${NC}
${BOLD}DIR  :${NC} $ARS
${BOLD}FILES:${NC} $(find "$ARS" -type f | wc -l | tr -d ' ')

EOF

    if [ -x "$ROOT/payloads.sh" ]; then
        ARSENAL_IP="$IP" ARSENAL_PORT="$PORT" "$ROOT/payloads.sh" --compact
    else
        echo -e "${YELLOW}[!]${NC} payloads.sh missing or not executable."
    fi

    echo
    echo -e "${BOLD}${CYAN}=============================================================="
    echo -e "  Server starting on ${GREEN}http://$IP:$PORT/${CYAN}  (CTRL+C to stop)"
    echo -e "==============================================================${NC}"
    echo
fi

cd "$ARS"
if [ "$PORT" -lt 1024 ] && [ "$EUID" -ne 0 ]; then
    echo -e "${YELLOW}[!]${NC} Port $PORT requires sudo. Falling back to sudo..."
    exec sudo python3 -m http.server "$PORT"
else
    exec python3 -m http.server "$PORT"
fi
