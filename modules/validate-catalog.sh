#!/data/data/com.termux/files/usr/bin/bash

validate_catalog() {
    local file="$1"
    local errors=0
    local line_no=0
    local ids=""

    [ -f "$file" ] || {
        echo "[!] Catalog file not found."
        return 1
    }

    while IFS= read -r line || [ -n "$line" ]; do
        line_no=$((line_no + 1))

        [ -z "$line" ] && continue

        if ! printf '%s\n' "$line" | grep -qE '^[0-9]{3}\|'; then
            echo "[!] Line $line_no: invalid ID format"
            errors=$((errors + 1))
            continue
        fi

        IFS='|' read -r id name category description type target deps extra <<< "$line"

        if [ -n "$extra" ] || [ -z "$deps" ]; then
            # Seven fields are required; dependencies may be empty.
            field_count=$(printf '%s' "$line" | awk -F'|' '{print NF}')
            if [ "$field_count" -ne 7 ]; then
                echo "[!] Line $line_no: expected 7 fields, found $field_count"
                errors=$((errors + 1))
                continue
            fi
        fi

        if [ -z "$name" ] || [ -z "$category" ] || [ -z "$description" ] ||
           [ -z "$type" ] || [ -z "$target" ]; then
            echo "[!] Line $line_no: missing required field"
            errors=$((errors + 1))
        fi

        case "$type" in
            pkg|github|local) ;;
            *)
                echo "[!] Line $line_no: invalid type '$type'"
                errors=$((errors + 1))
                ;;
        esac

        if printf '%s\n' "$ids" | grep -qxF "$id"; then
            echo "[!] Line $line_no: duplicate ID '$id'"
            errors=$((errors + 1))
        fi

        ids="${ids}${id}"$'\n'
    done < "$file"

    if [ "$errors" -eq 0 ]; then
        return 0
    fi

    echo
    echo "[!] Catalog validation failed with $errors error(s)."
    return 1
}
