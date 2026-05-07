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

SERVER_PID=""

# Run python3 -m http.server in background but DON'T redirect its stderr —
# every incoming request is printed live in the same terminal, exactly like
# `python3 -m http.server` does standalone. Any prompt the user has typed
# below will be preserved by readline.
start_server() {
    cd "$ARS"
    if [ "$PORT" -lt 1024 ] && [ "$EUID" -ne 0 ]; then
        echo -e "${YELLOW}[!]${NC} Port $PORT requires sudo. Falling back to sudo..."
        sudo python3 -m http.server "$PORT" &
    else
        python3 -m http.server "$PORT" &
    fi
    SERVER_PID=$!
    cd "$ROOT"
    sleep 0.4
    if ! kill -0 "$SERVER_PID" 2>/dev/null; then
        echo -e "${RED}[x]${NC} Server failed to start."
        exit 1
    fi
}

cleanup() {
    if [ -n "$SERVER_PID" ] && kill -0 "$SERVER_PID" 2>/dev/null; then
        kill "$SERVER_PID" 2>/dev/null
        wait "$SERVER_PID" 2>/dev/null
    fi
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
  ${BOLD}LIVE :${NC} ${DIM}HTTP requests are printed below as they arrive${NC}
EOF
}

MENU="main"
MENU_DIRTY=1   # 1 = print full menu on next loop, 0 = print one-line strip only

# One-liner reminder strip shown when MENU_DIRTY=0
print_strip() {
    case "$MENU" in
        main)    echo -e "${DIM}[1] Linux  [2] Windows  [3] AD  [4] Other  |  [a]ll  [t]ools  [r]efresh  [m]enu  [q]uit${NC}" ;;
        linux)   echo -e "${DIM}LINUX:  [1] enum  [2] revshell  [3] transfer  |  [b]ack  [m]enu${NC}" ;;
        windows) echo -e "${DIM}WIN:    [1] enum  [2] tokens  [3] dump  [4] ps-revshell  [5] transfer  |  [b]ack  [m]enu${NC}" ;;
        ad)      echo -e "${DIM}AD:     [1] recon [2] kerber [3] asrep [4] dcsync [5] runas [6] lateral [7] sql [8] coerce [9] dump  |  [b]ack${NC}" ;;
        other)   echo -e "${DIM}OTHER:  [1] listener  [2] revshell  [3] transfer  [4] pivot  [5] fallback  |  [b]ack${NC}" ;;
    esac
}

print_menu() {
    case "$MENU" in
        main) cat <<EOF

${BOLD}${CYAN}━━━━━━━━━━━━━ MENU ━━━━━━━━━━━━━${NC}

  ${GREEN}1${NC})  Linux             ${DIM}(enum, privesc, file transfer)${NC}
  ${GREEN}2${NC})  Windows           ${DIM}(enum, privesc, token abuse)${NC}
  ${GREEN}3${NC})  Active Directory  ${DIM}(recon, kerberoast, dcsync, lateral, dump...)${NC}
  ${GREEN}4${NC})  Other             ${DIM}(listener, revshell, pivot, transfer)${NC}

  ${BOLD}META${NC}
  ${GREEN}a${NC})  Show ALL          ${DIM}(full compact cheatsheet)${NC}
  ${GREEN}t${NC})  Tool list         ${DIM}(ls of tools/)${NC}
  ${GREEN}r${NC})  Refresh IP        ${DIM}(re-detect tun0)${NC}
  ${GREEN}c${NC})  Clear screen
  ${GREEN}q${NC})  Quit              ${DIM}(stops the HTTP server)${NC}

  ${DIM}HTTP requests appear inline as targets fetch files.${NC}

EOF
            ;;
        linux) cat <<EOF

${BOLD}${CYAN}━━━━━━━ LINUX ━━━━━━━${NC}

  ${GREEN}1${NC})  Enum & Privesc      ${DIM}(linpeas, pspy, lse, linux-exploit-suggester)${NC}
  ${GREEN}2${NC})  Reverse shells      ${DIM}(bash/python/perl oneliners)${NC}
  ${GREEN}3${NC})  File transfer       ${DIM}(wget, curl, socat)${NC}

  ${GREEN}b${NC})  Back to main menu

EOF
            ;;
        windows) cat <<EOF

${BOLD}${CYAN}━━━━━━━ WINDOWS ━━━━━━━${NC}

  ${GREEN}1${NC})  Enum & Privesc      ${DIM}(winPEAS, PrivescCheck, PowerUp, Sherlock, JAWS)${NC}
  ${GREEN}2${NC})  Token abuse         ${DIM}(PrintSpoofer, GodPotato, JuicyPotato(NG))${NC}
  ${GREEN}3${NC})  Credential dump     ${DIM}(mimikatz, SafetyKatz, LaZagne, comsvcs LSASS)${NC}
  ${GREEN}4${NC})  PowerShell revshell ${DIM}(Invoke-PowerShellTcp, powercat)${NC}
  ${GREEN}5${NC})  File transfer       ${DIM}(nc.exe, plink, certutil, bitsadmin)${NC}

  ${GREEN}b${NC})  Back to main menu

EOF
            ;;
        ad) cat <<EOF

${BOLD}${CYAN}━━━━━━━ ACTIVE DIRECTORY ━━━━━━━${NC}

  ${GREEN}1${NC})  Recon               ${DIM}(PowerView, SharpHound, kerbrute, LAPSToolkit, adPEAS)${NC}
  ${GREEN}2${NC})  Kerberoast          ${DIM}(Rubeus + impacket-GetUserSPNs + hashcat -m 13100)${NC}
  ${GREEN}3${NC})  AS-REPRoast         ${DIM}(Rubeus + impacket-GetNPUsers + hashcat -m 18200)${NC}
  ${GREEN}4${NC})  DCSync              ${DIM}(mimikatz lsadump + impacket-secretsdump)${NC}
  ${GREEN}5${NC})  RunasCs             ${DIM}(user pivot with cleartext creds)${NC}
  ${GREEN}6${NC})  Lateral movement    ${DIM}(PsExec, wmiexec, smbexec, evil-winrm)${NC}
  ${GREEN}7${NC})  PowerUpSQL          ${DIM}(MSSQL chain, xp_cmdshell, linked servers)${NC}
  ${GREEN}8${NC})  Coercion + AD CS    ${DIM}(PetitPotam, Certify, ntlmrelayx)${NC}
  ${GREEN}9${NC})  Credential dump     ${DIM}(mimikatz, SafetyKatz, LaZagne, comsvcs)${NC}

  ${GREEN}b${NC})  Back to main menu

EOF
            ;;
        other) cat <<EOF

${BOLD}${CYAN}━━━━━━━ OTHER ━━━━━━━${NC}

  ${GREEN}1${NC})  Listener            ${DIM}(Kali side - nc, pwncat-cs, msfconsole)${NC}
  ${GREEN}2${NC})  Reverse shell       ${DIM}(bash/python/ps oneliners, all platforms)${NC}
  ${GREEN}3${NC})  File transfer       ${DIM}(nc, plink, socat, smb-share)${NC}
  ${GREEN}4${NC})  Pivot / tunnel      ${DIM}(chisel, ligolo-ng, proxychains)${NC}
  ${GREEN}5${NC})  Fallback patterns   ${DIM}(when AV blocks something)${NC}

  ${GREEN}b${NC})  Back to main menu

EOF
            ;;
    esac
}

# Map current-menu + choice to payloads.sh --section name
section_for() {
    local choice="$1"
    case "$MENU" in
        linux)
            case "$choice" in
                1) echo linux ;;
                2) echo revshell ;;   # bash/python/perl applicable on Linux
                3) echo transfer ;;
            esac ;;
        windows)
            case "$choice" in
                1) echo windows ;;
                2) echo tokens ;;
                3) echo dump ;;       # mimikatz / safetykatz / lazagne / comsvcs
                4) echo revshell ;;   # ps-tcp / powercat in revshell section
                5) echo transfer ;;
            esac ;;
        ad)
            case "$choice" in
                1) echo ad-recon ;;
                2) echo kerberoast ;;
                3) echo asreproast ;;
                4) echo dcsync ;;
                5) echo runas ;;
                6) echo lateral ;;
                7) echo powerupsql ;;
                8) echo coercion ;;
                9) echo dump ;;
            esac ;;
        other)
            case "$choice" in
                1) echo listener ;;
                2) echo revshell ;;
                3) echo transfer ;;
                4) echo pivot ;;
                5) echo fallback ;;
            esac ;;
        main)
            case "$choice" in
                a|A) echo all ;;
            esac ;;
    esac
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
    wait "$SERVER_PID"
    exit 0
fi

# ---- interactive menu loop ----
while :; do
    if [ "$MENU_DIRTY" -eq 1 ]; then
        print_menu
        MENU_DIRTY=0
    else
        print_strip
    fi
    # Single-keystroke input (no Enter needed). All menu options are 1 char.
    # Add a newline manually since -n1 doesn't echo one.
    printf "%s" "$(echo -e ${BOLD}${GREEN}${MENU}>${NC} )"
    read -rsn1 choice
    echo "$choice"
    choice="${choice// /}"
    case "$choice" in
        q|Q|exit|quit) break ;;
        c|C|clear) clear 2>/dev/null; print_banner; MENU_DIRTY=1 ;;
        m|M|menu|\?|help) MENU_DIRTY=1 ;;
        t|T|tools|ls) show_tools ;;
        r|R|refresh)
            IP="$(detect_ip)"
            export ARSENAL_IP="$IP"
            echo -e "${CYAN}[*]${NC} IP refreshed: ${GREEN}$IP${NC}"
            ;;
        b|B|back)
            MENU="main"; MENU_DIRTY=1
            ;;
        '') : ;;  # ignore empty
        *)
            # On main menu, numeric 1-4 enters a submenu
            if [ "$MENU" = "main" ]; then
                case "$choice" in
                    1) MENU="linux";   MENU_DIRTY=1; continue ;;
                    2) MENU="windows"; MENU_DIRTY=1; continue ;;
                    3) MENU="ad";      MENU_DIRTY=1; continue ;;
                    4) MENU="other";   MENU_DIRTY=1; continue ;;
                esac
            fi
            sec="$(section_for "$choice")"
            if [ -z "$sec" ]; then
                echo -e "${RED}[!]${NC} Unknown choice: '$choice'  ${DIM}(type 'm' to see the menu)${NC}"
            else
                ARSENAL_IP="$IP" ARSENAL_PORT="$PORT" "$ROOT/payloads.sh" --section "$sec"
            fi
            ;;
    esac
done

echo
echo -e "${CYAN}[*]${NC} Stopping server..."
