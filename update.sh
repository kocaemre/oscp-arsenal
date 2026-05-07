#!/usr/bin/env bash
# update.sh - Pulls the latest version of every tool (run this before exam day).
set -u
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "[*] Backing up current tools/ ..."
if [ -d "$ROOT/tools" ]; then
    mv "$ROOT/tools" "$ROOT/tools.old.$(date +%s)"
fi

echo "[*] Re-running build_arsenal.sh ..."
bash "$ROOT/build_arsenal.sh"

echo "[+] Update complete. Old dir: $ROOT/tools.old.*  (delete with: rm -rf $ROOT/tools.old.*)"
