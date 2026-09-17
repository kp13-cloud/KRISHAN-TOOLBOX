#!/data/data/com.termux/files/usr/bin/bash

BASE_DIR="$(cd "$(dirname "$0")" && pwd)"
CATALOG="$BASE_DIR/config/catalog.db"
CACHE="$BASE_DIR/cache"
TOOLS="$BASE_DIR/tools"

mkdir -p "$CACHE" "$TOOLS"

C='\033[1;36m'
G='\033[1;32m'
Y='\033[1;33m'
R='\033[1;31m'
W='\033[1;37m'
M='\033[1;35m'
N='\033[0m'

banner() {
    clear
    echo
    printf "${C}"
    if command -v figlet >/dev/null 2>&1; then
        figlet "KRISHAN"
        figlet "TOOLBOX"
    else
        echo "========================"
        echo "     KRISHAN TOOLBOX"
        echo "========================"
    fi
    printf "${N}"
    echo -e "${M}        V1.1${N}"
    echo -e "${W}  400+ Modular Termux Tools${N}"
    echo -e "${C}  Created by KRISHAN SINGH SIDHU${N}"
    echo
}

total_tools() {
    grep -c '^[0-9]' "$CATALOG"
}

is_installed() {
    local type="$1"
    local target="$2"

    case "$type" in
        pkg)
            command -v "$target" >/dev/null 2>&1
            ;;
        github)
            [ -d "$TOOLS/$(basename "$target" .git)" ]
            ;;
        local)
            [ -f "$TOOLS/$target" ] || [ -d "$TOOLS/$target" ]
            ;;
    esac
}

status_icon() {
    if is_installed "$1" "$2"; then
        echo -e "${G}[✓]${N}"
    else
        echo -e "${R}[ ]${N}"
    fi
}

show_page() {
    local page="$1"
    local per_page=20
    local start=$(( (page - 1) * per_page + 1 ))
    local end=$(( page * per_page ))
    local total
    total=$(total_tools)

    banner

    echo -e "${Y}Tools $start-$end of $total${N}"
    echo

    awk -F'|' -v s="$start" -v e="$end" '
        $1 >= s && $1 <= e {print}
    ' "$CATALOG" |
    while IFS='|' read -r id name category description type target
    do
        status_icon "$type" "$target" >/tmp/kt_status
        status=$(cat /tmp/kt_status)

        printf "%s ${Y}[%03d]${N} %-25s ${C}%-18s${N}\n" \
            "$status" "$id" "$name" "$category"
    done

    echo
    echo "${C}N${N}=next  ${C}P${N}=previous  ${C}S${N}=search  ${C}Q${N}=back"
    echo
}

browse_tools() {
    local page=1
    local total
    total=$(total_tools)
    local pages=$(( (total + 19) / 20 ))

    while true
    do
        show_page "$page"
        read -p "Command: " action

        case "$action" in
            n|N)
                [ "$page" -lt "$pages" ] && page=$((page + 1))
                ;;
            p|P)
                [ "$page" -gt 1 ] && page=$((page - 1))
                ;;
            s|S)
                search_tools
                ;;
            q|Q)
                return
                ;;
            ''|*[!0-9]*)
                echo -e "${R}Invalid command.${N}"
                sleep 1
                ;;
            *)
                install_tool "$action"
                read -p "Press Enter..."
                ;;
        esac
    done
}

search_tools() {
    read -p "Search name/category: " query
    echo

    grep -i "$query" "$CATALOG" |
    while IFS='|' read -r id name category description type target
    do
        status_icon "$type" "$target" >/tmp/kt_status
        status=$(cat /tmp/kt_status)

        echo -e "$status ${Y}[$id]${N} $name"
        echo -e "    ${C}$category${N} - $description"
        echo
    done

    read -p "Enter tool number to install, or Enter to return: " id
    [ -n "$id" ] && install_tool "$id"
}

install_tool() {
    local id="$1"

    local entry
    entry=$(grep "^$(printf '%03d' "$id")|" "$CATALOG")

    [ -z "$entry" ] && entry=$(grep "^$id|" "$CATALOG")

    if [ -z "$entry" ]; then
        echo -e "${R}Tool $id not found.${N}"
        return
    fi

    IFS='|' read -r num name category description type target <<< "$entry"

    echo
    echo -e "${C}Tool:${N} $name"
    echo -e "${C}Category:${N} $category"
    echo -e "${C}Description:${N} $description"
    echo -e "${C}Source:${N} $type"
    echo

    if is_installed "$type" "$target"; then
        echo -e "${G}[✓] Already installed.${N}"
        return
    fi

    read -p "Install $name? [y/N]: " answer
    [[ "$answer" != "y" && "$answer" != "Y" ]] && return

    case "$type" in
        pkg)
            echo -e "${Y}[+] Installing Termux package...${N}"
            pkg install -y "$target"
            ;;

        github)
            local dirname
            dirname="$(basename "$target" .git)"

            echo -e "${Y}[+] Downloading authorized GitHub project...${N}"

            if command -v git >/dev/null 2>&1; then
                git clone "$target" "$TOOLS/$dirname"
            else
                echo -e "${Y}[+] Installing Git...${N}"
                pkg install -y git
                git clone "$target" "$TOOLS/$dirname"
            fi
            ;;

        local)
            case "$target" in
                learning)
                    mkdir -p "$TOOLS/learning"
                    cat > "$TOOLS/learning/README.txt" <<'LEARN'
KRISHAN TOOLBOX - SECURITY LEARNING LAB

Use these exercises only with systems you own
or have explicit permission to test.

Topics:
- HTTP fundamentals
- DNS fundamentals
- Network discovery concepts
- Linux permissions
- Basic defensive security
- Log analysis
LEARN
                    ;;

                cli)
                    mkdir -p "$TOOLS/cli"
                    printf '# CLI Practice\n\nPractice basic Termux commands.\n' \
                        > "$TOOLS/cli/README.md"
                    ;;

                gitpractice)
                    mkdir -p "$TOOLS/gitpractice"
                    printf '# Git Practice\n\nPractice Git locally.\n' \
                        > "$TOOLS/gitpractice/README.md"
                    ;;
            esac
            ;;
    esac

    echo
    if is_installed "$type" "$target"; then
        echo -e "${G}[✓] $name installed successfully.${N}"
    else
        echo -e "${R}[!] Installation did not complete.${N}"
    fi
}

categories() {
    banner

    echo -e "${Y}Categories${N}"
    echo

    cut -d'|' -f3 "$CATALOG" |
        sort -u |
        nl -w2 -s') '

    echo
    read -p "Enter category number or Q: " choice

    [[ "$choice" == "q" || "$choice" == "Q" ]] && return

    category=$(cut -d'|' -f3 "$CATALOG" |
        sort -u |
        sed -n "${choice}p")

    [ -z "$category" ] && return

    banner
    echo -e "${Y}Category: $category${N}"
    echo

    grep "|$category|" "$CATALOG" |
    while IFS='|' read -r id name cat description type target
    do
        status_icon "$type" "$target" >/tmp/kt_status
        status=$(cat /tmp/kt_status)
        echo -e "$status ${Y}[$id]${N} $name - $description"
    done

    echo
    read -p "Enter tool number to install, or Enter to return: " id
    [ -n "$id" ] && install_tool "$id"
}

about() {
    banner
    echo -e "${W}KRISHAN TOOLBOX V1.1${N}"
    echo
    echo "A modular Termux utility manager."
    echo
    echo "Features:"
    echo "  • Categories"
    echo "  • Pagination"
    echo "  • Search"
    echo "  • Installed-tool detection"
    echo "  • Termux package installation"
    echo "  • Authorized GitHub project downloads"
    echo "  • Local modules"
    echo
    echo "Only install/use security tools on systems"
    echo "you own or are explicitly authorized to test."
    echo
    read -p "Press Enter..."
}

main() {
    while true
    do
        banner

        echo -e "${Y}[1]${N} Browse Tools"
        echo -e "${Y}[2]${N} Categories"
        echo -e "${Y}[3]${N} Search"
        echo -e "${Y}[4]${N} Install by Number"
        echo -e "${Y}[5]${N} Update Termux"
        echo -e "${Y}[6]${N} About"
        echo -e "${Y}[7]${N} Update Tool Catalog"
        echo -e "${Y}[8]${N} Exit"
        echo

        read -p "Select: " option

        case "$option" in
            1)
                browse_tools
                ;;

            2)
                categories
                ;;

            3)
                search_tools
                read -p "Press Enter..."
                ;;

            4)
                read -p "Tool number: " id
                install_tool "$id"
                read -p "Press Enter..."
                ;;

            5)
                pkg update
                ;;

            6)
                about
                ;;

            7)
                bash "$BASE_DIR/modules/update-catalog.sh"
                read -p "Press Enter..."
                ;;

            8)
                clear
                exit 0
                ;;

            *)
                echo -e "${R}Invalid option.${N}"
                sleep 1
                ;;
        esac
    done
}

main
