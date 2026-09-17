#!/data/data/com.termux/files/usr/bin/bash

install_dependencies() {
    local deps="$1"

    [ -z "$deps" ] && return 0

    IFS=',' read -ra packages <<< "$deps"

    for package in "${packages[@]}"
    do
        [ -z "$package" ] && continue

        if ! command -v "$package" >/dev/null 2>&1; then
            echo "[+] Installing dependency: $package"
            pkg install -y "$package"
        else
            echo "[✓] Dependency available: $package"
        fi
    done
}
