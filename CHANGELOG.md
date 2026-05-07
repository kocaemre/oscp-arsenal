# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [1.1.0] - 2026-05-07

### Added

#### New tools
- `RunasCs.exe` + `Invoke-RunasCs.ps1` (antonioCoco/RunasCs) — alternate-credential program execution; critical for AD pivoting when WinRM/PsExec aren't available.
- `PowerUpSQL.ps1` (NetSPI) — MSSQL Server attack toolkit: discovery, xp_cmdshell, linked-server crawl, IMPERSONATE abuse.
- `PsExec.exe` + `PsExec64.exe` (Sysinternals) — classic Windows-to-Windows lateral movement when you have admin creds.
- `LAPSToolkit.ps1` (leoloobeek) — read LAPS-managed local admin passwords from AD when current user has the read permission.
- `reverse.jsp` (SecLists FuzzDB) — JSP reverse shell using `Runtime.exec`.
- `shell-laudanum.aspx` (SecLists Laudanum) — ASPX shell with file browser + cmd.

#### New AD-attack sections in compact mode
Phase 5 was split from one big "AD ATTACK" block into nine technique-specific sections, each with copy-paste recipes for both Windows-side (Rubeus/mimikatz) and Kali-side (impacket) approaches:
- `[5b]` Kerberoast (Rubeus + impacket-GetUserSPNs + hashcat -m 13100)
- `[5c]` AS-REPRoast (Rubeus + impacket-GetNPUsers + hashcat -m 18200)
- `[5d]` DCSync (mimikatz lsadump + impacket-secretsdump variants)
- `[5e]` RunasCs (with `-l 8` double-hop fix)
- `[5f]` Lateral movement (PsExec, wmiexec, smbexec, evil-winrm)
- `[5g]` PowerUpSQL (six recipes: discovery → audit → xp_cmdshell → linked → impersonate → full audit)
- `[5h]` Coercion + AD CS (PetitPotam + Certify + ntlmrelayx)
- `[5i]` Credential dump (mimikatz, SafetyKatz, LaZagne, comsvcs LSASS minidump)

#### Interactive menu
- `serve.sh` is now a launcher: starts the HTTP server in the background and drops the user into a numeric menu. New keys: `1-4` enter submenus (Linux / Windows / AD / Other), `b` returns to main, `m` re-prints the menu, `t` lists tool inventory, `r` re-detects `tun0`, `c` clears, `q` quits.
- Two-level menu structure: top has 4 categories, each with 3-9 sub-options (Linux=3, Windows=5, AD=9, Other=5).
- Single-keystroke input — pressing a number selects immediately, no Enter needed.
- Inline strip: after a section is shown, a one-line shortcut strip is printed instead of the full menu, keeping the screen clean.
- Live HTTP request output: `python3 -m http.server` stderr is no longer redirected, so every fetch from a target machine prints in the same terminal as it happens — no extra logging or `tail -f` needed.

#### Compact mode
- New `--section <name>` / `-s <name>` flag on `payloads.sh` that filters the compact output to a single phase. Section guards added throughout (`if show <id>; then ... fi`).
- `pspy` recipe wraps in `timeout 120` so it auto-exits after 2 minutes.
- Blank line between every row in compact mode for cleaner copy-paste.
- `LaZagne` now also reachable from `Windows > 3) Credential dump`, not just AD menu.

### Fixed

- **6 broken upstream URLs** that 404'd at build time (caught by CI):
  - `winPEAS.ps1` removed (peass-ng dropped it from releases)
  - `Watson.ps1` removed (rasta-mouse repo is C#-only)
  - `PrivescCheck.ps1` switched to GitHub release asset URL
  - `socat-linux-x64` switched to `andrew-d/static-binaries`
  - `LaZagne` Linux now uses `Linux/laZagne.py` source (no official Linux binary)
  - `chisel-windows.exe` upstream switched .gz → .zip; build now extracts the zip
- Webshell URLs (`tennc/webshell` repo restructured): `cmd.jsp` and `cmd.aspx` switched to `danielmiessler/SecLists/Web-Shells/FuzzDB/`.
- ligolo-ng binaries are now extracted at build time (`ligolo-proxy`, `ligolo-agent-linux`, `ligolo-agent-windows.exe`) so target shells don't have to `tar xzf` / `Expand-Archive` in-place.
- Stale `<ESC>[0m` file accidentally committed during the menu refactor was removed.
- `amsi_b64.sh -winpeas` shortcut (winPEAS.ps1 no longer exists) replaced with `-powerup` and `-privescchk` (both `.ps1`, AMSI-relevant).
- All Turkish strings in scripts translated to English for consistency.

## [1.0.0] - 2026-05-07

### Added

#### Core scripts
- `build_arsenal.sh` — populates `tools/` from Kali's local paths (`/usr/share/peass`, `/usr/bin/pspy64`, `/usr/share/windows-resources/binaries/`) with GitHub release fallbacks. Idempotent.
- `serve.sh` — auto-detects `tun0` IP, prints a kill-chain compact cheatsheet, then starts `python3 -m http.server`. Supports `--no-banner` and custom port arg.
- `payloads.sh` — generates copy-paste oneliners. Two modes:
  - default verbose: every tool with all delivery variants (wget/curl/iwr/iex/certutil/bitsadmin)
  - `--compact`: 7-phase kill-chain table (Listener → Reverse Shell → Linux Enum → Windows Enum/Token Abuse → AD Recon/Attack/Dump → Transfer → Pivot → Fallbacks)
  - filter: `./payloads.sh winpeas` for a single tool
- `update.sh` — backs up `tools/` to `tools.old.<ts>/` and re-runs build to refresh from latest upstream releases.
- `aliases.sh` — source-able shell shortcuts: `myip`, `arsenal-serve`, `revshell <ip> <port>`, `nc4444`, `smb-share`, `lpeas`, `wpeas`.
- `msfgen.sh` — `msfvenom` wrapper. Auto-detects `tun0` IP. Targets: `windows`, `linux`, `ps1`, `php`, `aspx`, `war`, `all`.
- `amsi_b64.sh` — wraps a PowerShell command with AMSI + ETW bypass and base64-encodes for `powershell -ep bypass -e <B64>`. Shortcuts: `-winpeas`, `-revshell <port>`.

#### Tools (Linux)
- linPEAS (full + small) · pspy64 · pspy32 · lse.sh · linux-exploit-suggester · les2 · LaZagne (linux binary) · static socat

#### Tools (Windows enum & privesc)
- winPEAS (x64/x86/bat/ps1) · PrivescCheck · PowerUp · Sherlock · Watson · JAWS · Seatbelt · accesschk

#### Tools (Token abuse)
- PrintSpoofer (32/64) · GodPotato (NET4/NET35) · JuicyPotato · JuicyPotatoNG

#### Tools (Active Directory)
- PowerView · SharpHound (ps1+exe zip) · Rubeus · Certify · SafetyKatz · mimikatz · kerbrute (linux+windows) · PetitPotam · adPEAS · enum4linux-ng · Invoke-Mimikatz · Invoke-Kerberoast · LaZagne (windows)

#### Tools (Transfer & shells)
- nc.exe (32/64) · plink.exe · socat · powercat · Invoke-PowerShellTcp · php-reverse-shell · cmd.jsp · cmdasp.aspx

#### Tools (Pivot)
- chisel (linux + windows, extracted binaries from `.gz`)
- ligolo-ng (proxy + agent linux + agent windows, extracted from tar.gz/zip — no manual extraction needed on target)

#### Repo infrastructure
- MIT License
- Comprehensive README with kill-chain workflow, fallback patterns table, requirements, and credits to all upstream authors
- `.gitignore` excluding `tools/` (binaries fetched on demand to keep repo clone small)
- GitHub Actions workflow (`check-tools.yml`) — runs weekly to detect broken upstream URLs early, plus syntax-checks all bash scripts on every push

[Unreleased]: https://github.com/kocaemre/oscp-arsenal/compare/v1.1.0...HEAD
[1.1.0]: https://github.com/kocaemre/oscp-arsenal/releases/tag/v1.1.0
[1.0.0]: https://github.com/kocaemre/oscp-arsenal/releases/tag/v1.0.0
