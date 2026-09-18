#!/data/data/com.termux/files/usr/bin/bash

BASE_DIR="$(cd "$(dirname "$0")/.." && pwd)"
BACKUP_DIR="$BASE_DIR/backups"

create_backup() {
    mkdir -p "$BACKUP_DIR"

    local stamp
    stamp="$(date '+%Y%m%d-%H%M%S')"
    local file="$BACKUP_DIR/toolbox-$stamp.tar.gz"

    echo
    echo "[+] Creating backup..."

    mkdir -p "$BASE_DIR/config"

    # Ensure optional configuration files exist.
    [ -f "$BASE_DIR/config/catalog.db" ] || touch "$BASE_DIR/config/catalog.db"
    [ -f "$BASE_DIR/config/favorites.db" ] || touch "$BASE_DIR/config/favorites.db"

    if tar -czf "$file" \
        -C "$BASE_DIR" \
        config/catalog.db \
        config/favorites.db
    then
        echo
        echo "[✓] Backup created successfully."
        echo "    $(basename "$file")"
        echo "    Location: $file"
    else
        rm -f "$file"
        echo
        echo "[!] Backup failed."
    fi

    echo
    read -rp "Press Enter..."
}

list_backups() {
    echo
    echo "Available backups:"
    echo

    if ! ls "$BACKUP_DIR"/toolbox-*.tar.gz >/dev/null 2>&1; then
        echo "No backups found."
    else
        ls -lh "$BACKUP_DIR"/toolbox-*.tar.gz
    fi

    echo
    read -rp "Press Enter..."
}

restore_backup() {
    echo
    echo "Available backups:"
    echo

    local files=()

    while IFS= read -r file; do
        files+=("$file")
    done < <(find "$BACKUP_DIR" -maxdepth 1 -type f -name 'toolbox-*.tar.gz' | sort)

    if [ "${#files[@]}" -eq 0 ]; then
        echo "[!] No backups found."
        read -rp "Press Enter..."
        return
    fi

    local i=1

    for file in "${files[@]}"; do
        echo "[$i] $(basename "$file")"
        i=$((i + 1))
    done

    echo
    read -rp "Select backup number: " num

    if ! [[ "$num" =~ ^[0-9]+$ ]] ||
       [ "$num" -lt 1 ] ||
       [ "$num" -gt "${#files[@]}" ]; then
        echo "[!] Invalid selection."
        sleep 1
        return
    fi

    local selected="${files[$((num-1))]}"

    echo
    echo "[!] This will restore catalog and favorites."
    read -rp "Type RESTORE to confirm: " confirm

    if [ "$confirm" != "RESTORE" ]; then
        echo "[i] Restore cancelled."
        sleep 1
        return
    fi

    if tar -xzf "$selected" -C "$BASE_DIR"; then
        echo "[✓] Backup restored successfully."
    else
        echo "[!] Restore failed."
    fi

    echo
    read -rp "Press Enter..."
}

backup_restore() {
    while true; do
        clear
        banner

        echo "════════════════════════════════════════════════════════"
        echo "                  BACKUP & RESTORE"
        echo "════════════════════════════════════════════════════════"
        echo
        echo "[1] Create backup"
        echo "[2] Restore backup"
        echo "[3] List backups"
        echo "[4] Back"
        echo

        read -rp "Select: " choice

        case "$choice" in
            1) create_backup ;;
            2) restore_backup ;;
            3) list_backups ;;
            4) return ;;
            *) echo "[!] Invalid option."; sleep 1 ;;
        esac
    done
}
