#!/usr/bin/env bash
# serve.sh - Starts python3 -m http.server in background, then drops you into an
# interactive menu so you can pull up payload commands by phase number.
# Auto-detects tun0 IP. Falls back to tun1 / eth0 / first non-loopback.
#
# Usage:
#   ./serve.sh                 # default port 8000, interactive menu
#   ./serve.sh 80              # custom port (sudo if <1024)
#   ./serve.sh --no-menu       # just start the server, no interactive menu (old behavior)
#   ./serve.sh --dump          # print full compact cheatsheet then start server
set -u

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ARS="$ROOT/tools"

GREEN=$'\033[0;32m'; YELLOW=$'\033[1;33m'; CYAN=$'\033[0;36m'; RED=$'\033[0;31m'; BOLD=$'\033[1m'; DIM=$'\033[2m'; NC=$'\033[0m'

PORT=8000
MODE="menu"
for a in "$@"; do
    case "$a" in
        --no-menu) MODE="quiet" ;;
        --dump)    MODE="dump" ;;
        --help|-h)
            sed -n '2,10p' "$0" | sed 's/^# \?//'
            exit 0 ;;
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
    for iface in tun0 tun1 eth0; do
        ip=$(ip -4 addr show "$iface" 2>/dev/null | awk '/inet /{print $2}' | cut -d/ -f1 | head -1)
        [ -n "$ip" ] && { echo "$ip"; return; }
    done
    ip=$(ifconfig 2>/dev/null | awk '/inet /{print $2}' | grep -v 127.0.0.1 | head -1)
    [ -n "$ip" ] && { echo "$ip"; return; }
    echo "0.0.0.0"
}

IP="$(detect_ip)"
export ARSENAL_IP="$IP"
export ARSENAL_PORT="$PORT"

LOGFILE="$(mktemp -t arsenal-server.XXXXXX.log)"
SERVER_PID=""

start_server() {
    cd "$ARS"
    if [ "$PORT" -lt 1024 ] && [ "$EUID" -ne 0 ]; then
        echo -e "${YELLOW}[!]${NC} Port $PORT requires sudo. Falling back to sudo..."
        sudo python3 -m http.server "$PORT" > "$LOGFILE" 2>&1 &
    else
        python3 -m http.server "$PORT" > "$LOGFILE" 2>&1 &
    fi
    SERVER_PID=$!
    cd "$ROOT"
    sleep 0.4
    if ! kill -0 "$SERVER_PID" 2>/dev/null; then
        echo -e "${RED}[x]${NC} Server failed to start. Last lines:"
        tail -10 "$LOGFILE"
        exit 1
    fi
}

cleanup() {
    if [ -n "$SERVER_PID" ] && kill -0 "$SERVER_PID" 2>/dev/null; then
        kill "$SERVER_PID" 2>/dev/null
        wait "$SERVER_PID" 2>/dev/null
    fi
    rm -f "$LOGFILE"
}
trap cleanup EXIT INT TERM

print_banner() {
    cat <<EOF

${BOLD}${CYAN}╔════════════════════════════════════════════════════╗
║              OSCP ARSENAL                          ║
╚════════════════════════════════════════════════════╝${NC}
  ${BOLD}URL  :${NC} ${GREEN}http://$IP:$PORT/${NC}
  ${BOLD}DIR  :${NC} $ARS
  ${BOLD}FILES:${NC} $(find "$ARS" -type f 2>/dev/null | wc -l | tr -d ' ')
  ${BOLD}LOG  :${NC} $LOGFILE  ${DIM}([s] to view)${NC}
EOF
}

print_menu() {
    cat <<EOF

${BOLD}${CYAN}━━━━━━━━━━━━━ MENU ━━━━━━━━━━━━━${NC}

  ${BOLD}KILL-CHAIN PHASES${NC}
  ${GREEN}1${NC})  Listener           ${DIM}(Kali side - nc/pwncat/msf)${NC}
  ${GREEN}2${NC})  Reverse shell      ${DIM}(bash/python/ps oneliners)${NC}
  ${GREEN}3${NC})  Linux enum         ${DIM}(linpeas, pspy, lse, les)${NC}
  ${GREEN}4${NC})  Windows enum       ${DIM}(winPEAS, PowerUp, Sherlock, JAWS)${NC}
  ${GREEN}5${NC})  Token abuse        ${DIM}(PrintSpoofer, GodPotato, JuicyPotato)${NC}

  ${BOLD}ACTIVE DIRECTORY${NC}
  ${GREEN}6${NC})  AD recon           ${DIM}(PowerView, SharpHound, kerbrute, LAPS)${NC}
  ${GREEN}7${NC})  Kerberoast         ${DIM}(Rubeus + impacket + hashcat)${NC}
  ${GREEN}8${NC})  AS-REPRoast        ${DIM}(Rubeus + impacket + hashcat)${NC}
  ${GREEN}9${NC})  DCSync             ${DIM}(mimikatz + secretsdump)${NC}
  ${GREEN}10${NC}) RunasCs            ${DIM}(user pivot with cleartext creds)${NC}
  ${GREEN}11${NC}) Lateral movement   ${DIM}(PsExec, wmiexec, evil-winrm)${NC}
  ${GREEN}12${NC}) PowerUpSQL         ${DIM}(MSSQL chain, xp_cmdshell)${NC}
  ${GREEN}13${NC}) Coercion + AD CS   ${DIM}(PetitPotam, Certify, ntlmrelayx)${NC}
  ${GREEN}14${NC}) Credential dump    ${DIM}(mimikatz, LaZagne, comsvcs)${NC}

  ${BOLD}TRANSPORT${NC}
  ${GREEN}15${NC}) File transfer      ${DIM}(nc, plink, socat, smb-share)${NC}
  ${GREEN}16${NC}) Pivot / tunnel     ${DIM}(chisel, ligolo)${NC}

  ${BOLD}META${NC}
  ${GREEN}a${NC})  Show ALL           ${DIM}(full compact cheatsheet)${NC}
  ${GREEN}f${NC})  Fallback patterns  ${DIM}(when AV blocks something)${NC}
  ${GREEN}s${NC})  Server log         ${DIM}(recent HTTP requests)${NC}
  ${GREEN}t${NC})  Tool list          ${DIM}(ls of tools/)${NC}
  ${GREEN}r${NC})  Refresh IP         ${DIM}(re-detect tun0)${NC}
  ${GREEN}c${NC})  Clear screen
  ${GREEN}q${NC})  Quit               ${DIM}(stops the HTTP server)${NC}

EOF
}

# Map menu choice to payloads.sh --section name
section_for() {
    case "$1" in
        1)  echo listener ;;
        2)  echo revshell ;;
        3)  echo linux ;;
        4)  echo windows ;;
        5)  echo tokens ;;
        6)  echo ad-recon ;;
        7)  echo kerberoast ;;
        8)  echo asreproast ;;
        9)  echo dcsync ;;
        10) echo runas ;;
        11) echo lateral ;;
        12) echo powerupsql ;;
        13) echo coercion ;;
        14) echo dump ;;
        15) echo transfer ;;
        16) echo pivot ;;
        f|F) echo fallback ;;
        a|A) echo all ;;
        *) echo "" ;;
    esac
}

show_log() {
    echo
    echo -e "${BOLD}${CYAN}--- Last 20 HTTP requests ---${NC}"
    if [ -s "$LOGFILE" ]; then
        # python3 -m http.server logs go to stderr; redirected to LOGFILE
        tail -20 "$LOGFILE" | grep -E "GET|POST|HEAD" || echo "  (no requests yet)"
    else
        echo "  (no log entries yet — has anything fetched yet?)"
    fi
}

show_tools() {
    echo
    echo -e "${BOLD}${CYAN}--- Tool inventory ---${NC}"
    for d in linux windows transfer ad enum revshells; do
        if [ -d "$ARS/$d" ]; then
            echo -e "${YELLOW}$d/${NC} ($(ls "$ARS/$d" | wc -l | tr -d ' ') files)"
            ls "$ARS/$d" | sed 's/^/  /'
            echo
        fi
    done
}

# ---- bootstrap ----
clear 2>/dev/null || true
start_server
print_banner

if [ "$MODE" = "dump" ]; then
    ARSENAL_IP="$IP" ARSENAL_PORT="$PORT" "$ROOT/payloads.sh" --compact
    echo
    echo -e "${CYAN}[*]${NC} Server running. Press CTRL+C to stop."
    wait "$SERVER_PID"
    exit 0
fi

if [ "$MODE" = "quiet" ]; then
    echo
    echo -e "${CYAN}[*]${NC} Server running on ${GREEN}http://$IP:$PORT/${NC}. Press CTRL+C to stop."
    tail -f "$LOGFILE"
    exit 0
fi

# ---- interactive menu loop ----
while :; do
    print_menu
    read -rp "$(echo -e ${BOLD}${GREEN})> ${NC}" choice
    choice="${choice// /}"
    case "$choice" in
        q|Q|exit|quit) break ;;
        c|C|clear) clear 2>/dev/null; print_banner ;;
        s|S|log) show_log ;;
        t|T|tools|ls) show_tools ;;
        r|R|refresh)
            IP="$(detect_ip)"
            export ARSENAL_IP="$IP"
            echo -e "${CYAN}[*]${NC} IP refreshed: ${GREEN}$IP${NC}"
            ;;
        '')
            : # ignore empty
            ;;
        *)
            sec="$(section_for "$choice")"
            if [ -z "$sec" ]; then
                echo -e "${RED}[!]${NC} Unknown choice: '$choice'"
            else
                ARSENAL_IP="$IP" ARSENAL_PORT="$PORT" "$ROOT/payloads.sh" --section "$sec"
            fi
            ;;
    esac
done

echo
echo -e "${CYAN}[*]${NC} Stopping server..."
