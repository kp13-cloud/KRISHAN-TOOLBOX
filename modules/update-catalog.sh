#!/data/data/com.termux/files/usr/bin/bash

BASE_DIR="$(cd "$(dirname "$0")/.." && pwd)"
REMOTE_URL="https://raw.githubusercontent.com/kp13-cloud/KRISHAN-TOOLBOX/main/catalog/catalog.db"

TEMP="$BASE_DIR/config/catalog.db.tmp"
BACKUP="$BASE_DIR/config/catalog.db.backup"

echo
echo "[+] Checking remote catalog..."
echo

command -v curl >/dev/null 2>&1 || {
    echo "[+] Installing curl..."
    pkg install -y curl || exit 1
}

if curl -fsSL --connect-timeout 10 "$REMOTE_URL" -o "$TEMP"; then

    if grep -qE '^[0-9]{3}\|' "$TEMP"; then

        cp "$BASE_DIR/config/catalog.db" "$BACKUP" 2>/dev/null

        mv "$TEMP" "$BASE_DIR/config/catalog.db"

        echo "[✓] Catalog updated successfully."
        echo "[i] Tools available: $(grep -cE '^[0-9]{3}\|' "$BASE_DIR/config/catalog.db")"

    else
        rm -f "$TEMP"
        echo "[!] Remote catalog failed validation."
    fi

else
    rm -f "$TEMP"
    echo "[!] Could not reach the remote catalog."
    echo "[i] Your existing catalog was kept."
fi

echo
