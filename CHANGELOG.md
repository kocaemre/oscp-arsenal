# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

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

[Unreleased]: https://github.com/kocaemre/oscp-arsenal/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/kocaemre/oscp-arsenal/releases/tag/v1.0.0
