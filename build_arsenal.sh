#!/usr/bin/env bash
# build_arsenal.sh - OSCP arsenal builder
# Copies tools from Kali (/usr/share, /opt) if available, otherwise pulls latest from GitHub.
# Idempotent: re-running fills missing files and skips existing ones.
set -u

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ARS="$ROOT/tools"
mkdir -p "$ARS"/{linux,windows,transfer,ad,enum,revshells,wordlists}

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; CYAN='\033[0;36m'; NC='\033[0m'
log()  { echo -e "${CYAN}[*]${NC} $*"; }
ok()   { echo -e "${GREEN}[+]${NC} $*"; }
warn() { echo -e "${YELLOW}[!]${NC} $*"; }
err()  { echo -e "${RED}[x]${NC} $*"; }

have() { command -v "$1" >/dev/null 2>&1; }
exists() { [ -e "$1" ] && [ -s "$1" ]; }

# fetch <dest> <url>
fetch() {
    local dest="$1" url="$2"
    if exists "$dest"; then
        ok "skip (exists): $(basename "$dest")"
        return 0
    fi
    log "download: $url -> $dest"
    if have curl; then
        curl -sSL --fail -o "$dest" "$url" || { err "failed: $url"; rm -f "$dest"; return 1; }
    elif have wget; then
        wget -q -O "$dest" "$url" || { err "failed: $url"; rm -f "$dest"; return 1; }
    else
        err "curl or wget required"; return 1
    fi
    ok "fetched: $(basename "$dest")"
}

# copy_or_fetch <src_path> <dest> <fallback_url>
copy_or_fetch() {
    local src="$1" dest="$2" url="$3"
    if exists "$dest"; then ok "skip (exists): $(basename "$dest")"; return 0; fi
    if exists "$src"; then
        cp "$src" "$dest" && ok "copied (local): $(basename "$dest")" && return 0
    fi
    fetch "$dest" "$url"
}

# github_release_url <owner/repo> <asset_pattern>  -> echoes URL
github_release_url() {
    local repo="$1" pattern="$2"
    local api="https://api.github.com/repos/$repo/releases/latest"
    if have curl; then
        curl -sSL "$api" | grep -oE '"browser_download_url": *"[^"]+"' \
            | cut -d'"' -f4 | grep -E "$pattern" | head -1
    fi
}

echo
log "===== LINUX ENUMERATION ====="
copy_or_fetch /usr/share/peass/linpeas/linpeas.sh \
    "$ARS/linux/linpeas.sh" \
    "https://github.com/peass-ng/PEASS-ng/releases/latest/download/linpeas.sh"

fetch "$ARS/linux/linpeas_small.sh" \
    "https://github.com/peass-ng/PEASS-ng/releases/latest/download/linpeas_small.sh"

copy_or_fetch /usr/bin/pspy64 "$ARS/linux/pspy64" \
    "https://github.com/DominicBreuker/pspy/releases/latest/download/pspy64"

fetch "$ARS/linux/pspy32" \
    "https://github.com/DominicBreuker/pspy/releases/latest/download/pspy32"

fetch "$ARS/linux/lse.sh" \
    "https://github.com/diego-treitos/linux-smart-enumeration/releases/latest/download/lse.sh"

fetch "$ARS/linux/linux-exploit-suggester.sh" \
    "https://raw.githubusercontent.com/mzet-/linux-exploit-suggester/master/linux-exploit-suggester.sh"

fetch "$ARS/linux/les2.pl" \
    "https://raw.githubusercontent.com/jondonas/linux-exploit-suggester-2/master/linux-exploit-suggester-2.pl"

echo
log "===== WINDOWS ENUMERATION ====="
copy_or_fetch /usr/share/peass/winpeas/winPEASx64.exe \
    "$ARS/windows/winPEASx64.exe" \
    "https://github.com/peass-ng/PEASS-ng/releases/latest/download/winPEASx64.exe"

copy_or_fetch /usr/share/peass/winpeas/winPEASx86.exe \
    "$ARS/windows/winPEASx86.exe" \
    "https://github.com/peass-ng/PEASS-ng/releases/latest/download/winPEASx86.exe"

copy_or_fetch /usr/share/peass/winpeas/winPEAS.bat \
    "$ARS/windows/winPEAS.bat" \
    "https://github.com/peass-ng/PEASS-ng/releases/latest/download/winPEAS.bat"

# NOTE: peass-ng releases no longer ship winPEAS.ps1 (removed upstream).
# Use winPEASx64.exe / winPEAS.bat instead.

fetch "$ARS/windows/PowerUp.ps1" \
    "https://raw.githubusercontent.com/PowerShellMafia/PowerSploit/master/Privesc/PowerUp.ps1"

fetch "$ARS/windows/Sherlock.ps1" \
    "https://raw.githubusercontent.com/rasta-mouse/Sherlock/master/Sherlock.ps1"

# NOTE: Watson upstream is C# only; no .ps1 in repo. Use Sherlock.ps1 (legacy)
# or Watson.exe (must be self-compiled). Sherlock covers most CVEs.

fetch "$ARS/windows/jaws-enum.ps1" \
    "https://raw.githubusercontent.com/411Hall/JAWS/master/jaws-enum.ps1"

fetch "$ARS/windows/Seatbelt.exe" \
    "https://github.com/r3motecontrol/Ghostpack-CompiledBinaries/raw/master/Seatbelt.exe"

fetch "$ARS/windows/accesschk.exe" \
    "https://live.sysinternals.com/accesschk.exe"

fetch "$ARS/windows/accesschk64.exe" \
    "https://live.sysinternals.com/accesschk64.exe"

# PrivescCheck - winPEAS'in modern, sessiz alternatifi (release'den compiled .ps1)
log "Fetching PrivescCheck.ps1 (latest release)..."
PC_URL=$(github_release_url "itm4n/PrivescCheck" "PrivescCheck\\.ps1$")
if [ -n "$PC_URL" ]; then
    fetch "$ARS/windows/PrivescCheck.ps1" "$PC_URL"
else
    warn "PrivescCheck release URL not found - skipping"
fi

# Token abuse / SeImpersonate - "potato" ailesi
log "Fetching potato exploits (SeImpersonate token abuse)..."

# JuicyPotato - eski Windows (Server 2012/2016, Win10 < 1809)
JP_URL=$(github_release_url "ohpe/juicy-potato" "JuicyPotato\\.exe$")
[ -n "$JP_URL" ] && fetch "$ARS/windows/JuicyPotato.exe" "$JP_URL"
# Fallback: bilinen statik link
[ ! -f "$ARS/windows/JuicyPotato.exe" ] && fetch "$ARS/windows/JuicyPotato.exe" \
    "https://github.com/ohpe/juicy-potato/releases/download/v0.1/JuicyPotato.exe"

# JuicyPotatoNG - JuicyPotato'nun Win10 1809+ icin yeniden yazimi
JPNG_URL=$(github_release_url "antonioCoco/JuicyPotatoNG" "JuicyPotatoNG\\.exe$")
[ -n "$JPNG_URL" ] && fetch "$ARS/windows/JuicyPotatoNG.exe" "$JPNG_URL"

# PrintSpoofer - Win10 1809+ / Server 2019 (modern)
PS_URL=$(github_release_url "itm4n/PrintSpoofer" "PrintSpoofer64\\.exe$")
[ -n "$PS_URL" ] && fetch "$ARS/windows/PrintSpoofer64.exe" "$PS_URL"
PS32_URL=$(github_release_url "itm4n/PrintSpoofer" "PrintSpoofer32\\.exe$")
[ -n "$PS32_URL" ] && fetch "$ARS/windows/PrintSpoofer32.exe" "$PS32_URL"

# GodPotato - PrintSpoofer'in patch'lendigi yerlerde calisir, .NET surumlerine gore
GP_NET4=$(github_release_url "BeichenDream/GodPotato" "GodPotato-NET4\\.exe$")
[ -n "$GP_NET4" ] && fetch "$ARS/windows/GodPotato-NET4.exe" "$GP_NET4"
GP_NET35=$(github_release_url "BeichenDream/GodPotato" "GodPotato-NET35\\.exe$")
[ -n "$GP_NET35" ] && fetch "$ARS/windows/GodPotato-NET35.exe" "$GP_NET35"

# RunasCs - alternate-credential program execution (lateral pivot when only creds + no PsExec)
log "Fetching RunasCs (runas with alternate creds)..."
RC_URL=$(github_release_url "antonioCoco/RunasCs" "RunasCs\\.zip$")
if [ -n "$RC_URL" ] && [ ! -f "$ARS/windows/RunasCs.exe" ]; then
    RC_TMP="$(mktemp -d)"
    fetch "$RC_TMP/rc.zip" "$RC_URL" \
        && (cd "$RC_TMP" && unzip -o rc.zip >/dev/null 2>&1) \
        && cp "$RC_TMP"/RunasCs.exe "$ARS/windows/RunasCs.exe" 2>/dev/null \
        && ok "extracted: RunasCs.exe"
    # Also include the PowerShell port (Invoke-RunasCs.ps1) if shipped in the zip
    [ -f "$RC_TMP/Invoke-RunasCs.ps1" ] && cp "$RC_TMP/Invoke-RunasCs.ps1" "$ARS/windows/Invoke-RunasCs.ps1"
    rm -rf "$RC_TMP"
fi
# PowerShell port from raw repo (works when .exe is blocked but ps1 isn't)
fetch "$ARS/windows/Invoke-RunasCs.ps1" \
    "https://raw.githubusercontent.com/antonioCoco/RunasCs/master/Invoke-RunasCs.ps1"

# PowerUpSQL - SQL Server attack toolkit (NetSPI). xp_cmdshell, linked servers, impersonation.
fetch "$ARS/windows/PowerUpSQL.ps1" \
    "https://raw.githubusercontent.com/NetSPI/PowerUpSQL/master/PowerUpSQL.ps1"

# LAPSToolkit - read LAPS-managed local admin passwords from AD
fetch "$ARS/ad/LAPSToolkit.ps1" \
    "https://raw.githubusercontent.com/leoloobeek/LAPSToolkit/master/LAPSToolkit.ps1"

# PsExec (Sysinternals) - classic Windows-to-Windows lateral movement
fetch "$ARS/transfer/PsExec.exe" \
    "https://live.sysinternals.com/PsExec.exe"
fetch "$ARS/transfer/PsExec64.exe" \
    "https://live.sysinternals.com/PsExec64.exe"

echo
log "===== TRANSFER / TUNNELING ====="
copy_or_fetch /usr/share/windows-resources/binaries/nc.exe \
    "$ARS/transfer/nc.exe" \
    "https://github.com/int0x33/nc.exe/raw/master/nc.exe"

fetch "$ARS/transfer/nc64.exe" \
    "https://github.com/int0x33/nc.exe/raw/master/nc64.exe"

copy_or_fetch /usr/share/windows-resources/binaries/plink.exe \
    "$ARS/transfer/plink.exe" \
    "https://the.earth.li/~sgtatham/putty/latest/w64/plink.exe"

fetch "$ARS/transfer/socat-linux-x64" \
    "https://github.com/andrew-d/static-binaries/raw/master/binaries/linux/x86_64/socat"

log "Fetching chisel..."
# Linux: .gz with "chisel_<ver>_linux_amd64" inside. Windows: .zip with "chisel.exe" inside.
CHISEL_URL_LINUX=$(github_release_url "jpillora/chisel" "linux_amd64\\.gz$")
CHISEL_URL_WIN=$(github_release_url "jpillora/chisel" "windows_amd64\\.zip$")
if [ -n "$CHISEL_URL_LINUX" ] && [ ! -f "$ARS/transfer/chisel-linux" ]; then
    fetch "$ARS/transfer/_chisel-linux.gz" "$CHISEL_URL_LINUX" \
        && gunzip -c "$ARS/transfer/_chisel-linux.gz" > "$ARS/transfer/chisel-linux" \
        && rm -f "$ARS/transfer/_chisel-linux.gz" \
        && chmod +x "$ARS/transfer/chisel-linux" \
        && ok "extracted: chisel-linux"
fi
if [ -n "$CHISEL_URL_WIN" ] && [ ! -f "$ARS/transfer/chisel-windows.exe" ]; then
    CTMP="$(mktemp -d)"
    fetch "$CTMP/cw.zip" "$CHISEL_URL_WIN" \
        && (cd "$CTMP" && unzip -o cw.zip >/dev/null 2>&1) \
        && cp "$CTMP"/chisel*.exe "$ARS/transfer/chisel-windows.exe" 2>/dev/null \
        && ok "extracted: chisel-windows.exe"
    rm -rf "$CTMP"
fi

log "Fetching ligolo-ng..."
LIGOLO_PROXY=$(github_release_url "nicocha30/ligolo-ng" "proxy.*linux_amd64.tar.gz")
LIGOLO_AGENT_LIN=$(github_release_url "nicocha30/ligolo-ng" "agent.*linux_amd64.tar.gz")
LIGOLO_AGENT_WIN=$(github_release_url "nicocha30/ligolo-ng" "agent.*windows_amd64.zip")
TMP_DIR="$(mktemp -d)"
if [ -n "$LIGOLO_PROXY" ] && [ ! -f "$ARS/transfer/ligolo-proxy" ]; then
    fetch "$TMP_DIR/lp.tar.gz" "$LIGOLO_PROXY" \
        && tar xzf "$TMP_DIR/lp.tar.gz" -C "$TMP_DIR" \
        && cp "$TMP_DIR/proxy" "$ARS/transfer/ligolo-proxy" \
        && chmod +x "$ARS/transfer/ligolo-proxy" \
        && ok "extracted: ligolo-proxy"
fi
if [ -n "$LIGOLO_AGENT_LIN" ] && [ ! -f "$ARS/transfer/ligolo-agent-linux" ]; then
    fetch "$TMP_DIR/la.tar.gz" "$LIGOLO_AGENT_LIN" \
        && tar xzf "$TMP_DIR/la.tar.gz" -C "$TMP_DIR" \
        && cp "$TMP_DIR/agent" "$ARS/transfer/ligolo-agent-linux" \
        && chmod +x "$ARS/transfer/ligolo-agent-linux" \
        && ok "extracted: ligolo-agent-linux"
fi
if [ -n "$LIGOLO_AGENT_WIN" ] && [ ! -f "$ARS/transfer/ligolo-agent-windows.exe" ]; then
    fetch "$TMP_DIR/law.zip" "$LIGOLO_AGENT_WIN" \
        && (cd "$TMP_DIR" && unzip -o law.zip >/dev/null 2>&1) \
        && cp "$TMP_DIR/agent.exe" "$ARS/transfer/ligolo-agent-windows.exe" \
        && ok "extracted: ligolo-agent-windows.exe"
fi
rm -rf "$TMP_DIR"

echo
log "===== ACTIVE DIRECTORY ====="
fetch "$ARS/ad/PowerView.ps1" \
    "https://raw.githubusercontent.com/PowerShellMafia/PowerSploit/master/Recon/PowerView.ps1"

fetch "$ARS/ad/PowerView_dev.ps1" \
    "https://raw.githubusercontent.com/PowerShellMafia/PowerSploit/dev/Recon/PowerView.ps1"

fetch "$ARS/ad/Invoke-Mimikatz.ps1" \
    "https://raw.githubusercontent.com/PowerShellMafia/PowerSploit/master/Exfiltration/Invoke-Mimikatz.ps1"

fetch "$ARS/ad/Invoke-Kerberoast.ps1" \
    "https://raw.githubusercontent.com/EmpireProject/Empire/master/data/module_source/credentials/Invoke-Kerberoast.ps1"

log "Fetching SharpHound..."
SH_URL=$(github_release_url "BloodHoundAD/SharpHound" "SharpHound.*\\.zip")
[ -n "$SH_URL" ] && fetch "$ARS/ad/SharpHound.zip" "$SH_URL"
fetch "$ARS/ad/SharpHound.ps1" \
    "https://raw.githubusercontent.com/BloodHoundAD/BloodHound/master/Collectors/SharpHound.ps1"

fetch "$ARS/ad/Rubeus.exe" \
    "https://github.com/r3motecontrol/Ghostpack-CompiledBinaries/raw/master/Rubeus.exe"

fetch "$ARS/ad/Certify.exe" \
    "https://github.com/r3motecontrol/Ghostpack-CompiledBinaries/raw/master/Certify.exe"

fetch "$ARS/ad/SafetyKatz.exe" \
    "https://github.com/r3motecontrol/Ghostpack-CompiledBinaries/raw/master/SafetyKatz.exe"

log "Fetching mimikatz..."
MIMI_URL=$(github_release_url "gentilkiwi/mimikatz" "mimikatz_trunk.zip")
[ -n "$MIMI_URL" ] && fetch "$ARS/ad/mimikatz_trunk.zip" "$MIMI_URL"

log "Fetching kerbrute..."
KB_LINUX=$(github_release_url "ropnop/kerbrute" "linux_amd64$")
KB_WIN=$(github_release_url "ropnop/kerbrute" "windows_amd64.exe")
[ -n "$KB_LINUX" ] && fetch "$ARS/ad/kerbrute_linux" "$KB_LINUX" && chmod +x "$ARS/ad/kerbrute_linux" 2>/dev/null
[ -n "$KB_WIN" ] && fetch "$ARS/ad/kerbrute_windows.exe" "$KB_WIN"

fetch "$ARS/ad/PetitPotam.py" \
    "https://raw.githubusercontent.com/topotam/PetitPotam/main/PetitPotam.py"

log "Fetching LaZagne (credential dumper)..."
# Windows: official compiled .exe from releases
LAZ_WIN=$(github_release_url "AlessandroZ/LaZagne" "lazagne\\.exe$|LaZagne\\.exe$")
[ -n "$LAZ_WIN" ] && fetch "$ARS/ad/LaZagne.exe" "$LAZ_WIN"
# Linux: no official binary - use Python source (target needs python).
# Repo has Linux/laZagne.py as the Linux entrypoint.
fetch "$ARS/linux/laZagne.py" \
    "https://raw.githubusercontent.com/AlessandroZ/LaZagne/master/Linux/laZagne.py"

echo
log "===== ENUM / RECON ====="
fetch "$ARS/enum/enum4linux-ng.py" \
    "https://raw.githubusercontent.com/cddmp/enum4linux-ng/master/enum4linux-ng.py"

fetch "$ARS/enum/adPEAS.ps1" \
    "https://raw.githubusercontent.com/61106960/adPEAS/main/adPEAS.ps1"

echo
log "===== REVERSE SHELLS ====="
fetch "$ARS/revshells/powercat.ps1" \
    "https://raw.githubusercontent.com/besimorhino/powercat/master/powercat.ps1"

fetch "$ARS/revshells/Invoke-PowerShellTcp.ps1" \
    "https://raw.githubusercontent.com/samratashok/nishang/master/Shells/Invoke-PowerShellTcp.ps1"

fetch "$ARS/revshells/php-reverse-shell.php" \
    "https://raw.githubusercontent.com/pentestmonkey/php-reverse-shell/master/php-reverse-shell.php"

fetch "$ARS/revshells/cmd.jsp" \
    "https://raw.githubusercontent.com/tennc/webshell/master/jsp/cmd.jsp"

fetch "$ARS/revshells/cmdasp.aspx" \
    "https://raw.githubusercontent.com/tennc/webshell/master/fuzzdb-webshell/aspx/cmdasp.aspx"

echo
log "===== WORDLISTS (referenced, not copied) ====="
if [ -f /usr/share/wordlists/rockyou.txt ]; then
    [ -L "$ARS/wordlists/rockyou.txt" ] || ln -sf /usr/share/wordlists/rockyou.txt "$ARS/wordlists/rockyou.txt"
    ok "rockyou.txt symlink created"
elif [ -f /usr/share/wordlists/rockyou.txt.gz ]; then
    warn "rockyou.txt.gz found, extract with: sudo gunzip /usr/share/wordlists/rockyou.txt.gz"
else
    warn "rockyou.txt not found. On Kali: sudo apt install wordlists"
fi

echo "Built: $(date)" > "$ARS/.last_build"

chmod +x "$ARS/linux"/* "$ARS/transfer/chisel-linux" "$ARS/transfer/socat-linux-x64" "$ARS/ad/kerbrute_linux" 2>/dev/null

echo
ok "Arsenal ready: $ARS"
log "Total files: $(find "$ARS" -type f | wc -l | tr -d ' ')"
log "Size: $(du -sh "$ARS" 2>/dev/null | awk '{print $1}')"
echo
log "Start the server:    ./serve.sh"
log "Print download cmds: ./payloads.sh"
