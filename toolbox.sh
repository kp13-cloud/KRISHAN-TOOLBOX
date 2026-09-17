#!/data/data/com.termux/files/usr/bin/bash

BASE_DIR="$(cd "$(dirname "$0")" && pwd)"
CATALOG="$BASE_DIR/config/catalog.db"
CACHE="$BASE_DIR/cache"
TOOLS="$BASE_DIR/tools"

mkdir -p "$CACHE" "$TOOLS"
source "$BASE_DIR/modules/dependencies.sh"

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
    echo -e "${W}  $(total_tools) Modular Termux Tools${N}"
    echo -e "${C}  Created by KRISHAN SINGH SIDHU${N}"
    echo
}

total_tools() {
    grep -c '^[0-9]' "$CATALOG"
}

is_installed() {
    local type="$1"
    local target="$2"

    install_dependencies "$dependencies"

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

tool_info() {
    local id="$1"
    local entry

    entry=$(grep "^$(printf '%03d' "$id")|" "$CATALOG")
    [ -z "$entry" ] && entry=$(grep "^$id|" "$CATALOG")

    if [ -z "$entry" ]; then
        echo -e "${R}Tool $id not found.${N}"
        return
    fi

    IFS='|' read -r num name category description type target dependencies <<< "$entry"

    echo
    echo -e "${C}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${N}"
    echo -e "${Y}Tool Information${N}"
    echo -e "${C}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${N}"
    echo
    echo -e "${W}ID:${N}          $num"
    echo -e "${W}Name:${N}        $name"
    echo -e "${W}Category:${N}    $category"
    echo -e "${W}Description:${N} $description"
    echo -e "${W}Source:${N}       $type"
    echo -e "${W}Target:${N}       $target"

    if [ -n "$dependencies" ]; then
        echo -e "${W}Dependencies:${N} $dependencies"
    else
        echo -e "${W}Dependencies:${N} None"
    fi

    if is_installed "$type" "$target"; then
        echo -e "${W}Status:${N}       ${G}Installed${N}"
    else
        echo -e "${W}Status:${N}       ${R}Not installed${N}"
    fi

    echo
    echo -e "${C}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${N}"
}
 
install_tool() {
    local id="$1"
    local entry

    entry=$(grep "^$(printf '%03d' "$id")|" "$CATALOG")
    [ -z "$entry" ] && entry=$(grep "^$id|" "$CATALOG")

    if [ -z "$entry" ]; then
        echo -e "${R}[!] Tool $id not found.${N}"
        return 1
    fi

    IFS='|' read -r num name category description type target dependencies <<< "$entry"

    banner

    echo -e "${Y}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${N}"
    echo -e "${C}Installing: ${W}$name${N}"
    echo -e "${Y}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${N}"
    echo
    echo -e "${C}Category:${N}    $category"
    echo -e "${C}Description:${N} $description"
    echo -e "${C}Source:${N}       $type"
    echo

    if is_installed "$type" "$target"; then
        echo -e "${G}[✓] Already installed.${N}"
        return 0
    fi

    if [ -n "$dependencies" ]; then
        echo -e "${Y}[+] Checking dependencies...${N}"
        install_dependencies "$dependencies" || {
            echo -e "${R}[!] Dependency installation failed.${N}"
            return 1
        }
    fi

    read -p "Continue with $name? [y/N]: " answer

    if [[ "$answer" != "y" && "$answer" != "Y" ]]; then
        echo -e "${Y}[i] Installation cancelled.${N}"
        return 0
    fi

    echo

    case "$type" in
        pkg)
            echo -e "${Y}[+] Installing Termux package: $target${N}"
            echo

            if pkg install -y "$target"; then
                echo
                if is_installed "$type" "$target"; then
                    echo -e "${G}[✓] $name installed successfully.${N}"
                else
                    echo -e "${Y}[i] Package installed, but its command could not be verified.${N}"
                fi
            else
                echo
                echo -e "${R}[!] Failed to install $name.${N}"
                echo -e "${Y}[i] Check your Termux repositories and internet connection.${N}"
                return 1
            fi
            ;;

        github)
            local dirname
            dirname="$(basename "$target" .git)"

            if [ -d "$TOOLS/$dirname" ]; then
                echo -e "${Y}[i] Project directory already exists.${N}"
                return 0
            fi

            if ! command -v git >/dev/null 2>&1; then
                echo -e "${Y}[+] Git is required. Installing Git...${N}"

                if ! pkg install -y git; then
                    echo -e "${R}[!] Could not install Git.${N}"
                    return 1
                fi
            fi

            echo -e "${Y}[+] Downloading authorized GitHub project...${N}"
            echo

            if git clone "$target" "$TOOLS/$dirname"; then
                echo
                echo -e "${G}[✓] $name downloaded successfully.${N}"
            else
                echo
                echo -e "${R}[!] Failed to download $name.${N}"
                rm -rf "$TOOLS/$dirname"
                return 1
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

                pythonpractice)
                    mkdir -p "$TOOLS/pythonpractice"
                    printf '# Python Practice\n\nPractice Python locally in Termux.\n' \
                        > "$TOOLS/pythonpractice/README.md"
                    ;;

                httpbasics)
                    mkdir -p "$TOOLS/httpbasics"
                    printf '# HTTP Basics\n\nLearn HTTP fundamentals using local development systems.\n' \
                        > "$TOOLS/httpbasics/README.md"
                    ;;

                dnsbasics)
                    mkdir -p "$TOOLS/dnsbasics"
                    printf '# DNS Basics\n\nLearn DNS concepts in authorized environments.\n' \
                        > "$TOOLS/dnsbasics/README.md"
                    ;;

                permissions)
                    mkdir -p "$TOOLS/permissions"
                    printf '# Linux Permissions\n\nPractice Linux permissions on files you own.\n' \
                        > "$TOOLS/permissions/README.md"
                    ;;

                logs)
                    mkdir -p "$TOOLS/logs"
                    printf '# Log Analysis\n\nPractice defensive log analysis with local sample files.\n' \
                        > "$TOOLS/logs/README.md"
                    ;;

                jsonpractice)
                    mkdir -p "$TOOLS/jsonpractice"
                    printf '# JSON Practice\n\nPractice JSON processing with jq.\n' \
                        > "$TOOLS/jsonpractice/README.md"
                    ;;

                shellpractice)
                    mkdir -p "$TOOLS/shellpractice"
                    printf '# Shell Practice\n\nPractice Bash scripting locally.\n' \
                        > "$TOOLS/shellpractice/README.md"
                    ;;
            esac

            echo -e "${G}[✓] $name installed successfully.${N}"
            ;;

        *)
            echo -e "${R}[!] Unknown installation type: $type${N}"
            return 1
            ;;
    esac

    echo
    read -p "Press Enter..."
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

health_check() {
    banner

    echo -e "${Y}KRISHAN TOOLBOX - SYSTEM HEALTH${N}"
    echo

    check_ok() {
        echo -e "${G}[✓]${N} $1"
    }

    check_fail() {
        echo -e "${R}[!]${N} $1"
    }

    if command -v bash >/dev/null 2>&1; then
        check_ok "Bash available"
    else
        check_fail "Bash missing"
    fi

    if command -v git >/dev/null 2>&1; then
        check_ok "Git available"
    else
        check_fail "Git missing"
    fi

    if command -v curl >/dev/null 2>&1; then
        check_ok "Curl available"
    else
        check_fail "Curl missing"
    fi

    if [ -d "$TOOLS" ]; then
        check_ok "Tools directory"
    else
        check_fail "Tools directory missing"
    fi

    if [ -d "$CACHE" ]; then
        check_ok "Cache directory"
    else
        check_fail "Cache directory missing"
    fi

    if [ -f "$CATALOG" ]; then
        check_ok "Catalog found"
    else
        check_fail "Catalog missing"
    fi

    if [ -f "$CATALOG" ]; then
        bad=$(awk -F'|' 'NF != 7 {count++} END {print count+0}' "$CATALOG")

        if [ "$bad" -eq 0 ]; then
            check_ok "Catalog format valid"
        else
            check_fail "Catalog has $bad invalid entries"
        fi
    fi

    if bash -n "$BASE_DIR/toolbox.sh" 2>/dev/null; then
        check_ok "toolbox.sh syntax"
    else
        check_fail "toolbox.sh syntax error"
    fi

    if bash -n "$BASE_DIR/modules/dependencies.sh" 2>/dev/null; then
        check_ok "dependencies.sh syntax"
    else
        check_fail "dependencies.sh syntax error"
    fi

    if bash -n "$BASE_DIR/modules/update-catalog.sh" 2>/dev/null; then
        check_ok "update-catalog.sh syntax"
    else
        check_fail "update-catalog.sh syntax error"
    fi

    echo
    echo -e "${C}Catalog entries:${N} $(total_tools)"
    echo -e "${C}Installed tools:${N} $(grep -c '^[0-9]' "$CATALOG" 2>/dev/null || echo 0)"
    echo
    read -p "Press Enter..."
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


installed_tools() {
    while true; do
        clear
        banner

        echo -e "${C}════════════════════════════════════════════════════════${N}"
        echo -e "${Y}                 INSTALLED TOOLS${N}"
        echo -e "${C}════════════════════════════════════════════════════════${N}"
        echo

        local found=0
        local i=1
        local dirs=()

        if [ -d "$TOOLS" ]; then
            while IFS= read -r dir; do
                [ -d "$dir" ] || continue
                local name
                name="$(basename "$dir")"

                echo -e "${G}[$i]${N} ${W}$name${N}"
                dirs+=("$dir")
                i=$((i + 1))
                found=1
            done < <(find "$TOOLS" -mindepth 1 -maxdepth 1 -type d | sort)
        fi

        if [ "$found" -eq 0 ]; then
            echo -e "${Y}No locally installed tools found.${N}"
            echo
            read -rp "Press Enter to return..."
            return
        fi

        echo
        echo -e "${C}[I]${N} Tool information"
        echo -e "${C}[O]${N} Open tool directory"
        echo -e "${C}[R]${N} Remove local tool"
        echo -e "${C}[Q]${N} Back"
        echo

        read -rp "Select: " choice
        choice="${choice,,}"

        case "$choice" in
            q)
                return
                ;;

            o)
                read -rp "Enter tool number: " num

                if [[ "$num" =~ ^[0-9]+$ ]] && [ "$num" -ge 1 ] && [ "$num" -le "${#dirs[@]}" ]; then
                    target="${dirs[$((num-1))]}"

                    echo
                    echo -e "${G}Directory:${N} $target"
                    echo
                    ls -lah -- "$target"
                    echo
                    read -rp "Press Enter to return..."
                else
                    echo -e "${R}[!] Invalid tool number.${N}"
                    sleep 1
                fi
                ;;

            i)
                read -rp "Enter tool number: " num

                if [[ "$num" =~ ^[0-9]+$ ]] && [ "$num" -ge 1 ] && [ "$num" -le "${#dirs[@]}" ]; then
                    target="${dirs[$((num-1))]}"
                    name="$(basename "$target")"

                    echo
                    echo -e "${C}════════════════════════════════════════════════════════${N}"
                    echo -e "${Y}TOOL INFORMATION${N}"
                    echo -e "${C}════════════════════════════════════════════════════════${N}"
                    echo -e "${W}Name:${N}      $name"
                    echo -e "${W}Location:${N}  $target"

                    if command -v du >/dev/null 2>&1; then
                        echo -e "${W}Size:${N}      $(du -sh -- "$target" 2>/dev/null | awk '{print $1}')"
                    fi

                    if [ -f "$target/README.md" ]; then
                        echo
                        echo -e "${C}README:${N}"
                        echo
                        sed -n '1,80p' "$target/README.md"
                    fi

                    echo
                    read -rp "Press Enter to return..."
                else
                    echo -e "${R}[!] Invalid tool number.${N}"
                    sleep 1
                fi
                ;;

            r)
                read -rp "Enter tool number to remove: " num

                if [[ "$num" =~ ^[0-9]+$ ]] && [ "$num" -ge 1 ] && [ "$num" -le "${#dirs[@]}" ]; then
                    target="${dirs[$((num-1))]}"
                    name="$(basename "$target")"

                    echo
                    echo -e "${Y}You are about to remove:${N} $name"
                    echo -e "${Y}Only the local toolbox copy will be removed.${N}"
                    echo

                    read -rp "Type REMOVE to confirm: " confirm

                    if [ "$confirm" = "REMOVE" ]; then
                        rm -rf -- "$target"
                        echo -e "${G}[✓] $name removed.${N}"
                    else
                        echo -e "${Y}[i] Removal cancelled.${N}"
                    fi

                    sleep 1
                else
                    echo -e "${R}[!] Invalid tool number.${N}"
                    sleep 1
                fi
                ;;

            *)
                echo -e "${R}[!] Invalid option.${N}"
                sleep 1
                ;;
        esac
    done
}


dashboard() {
    local catalog_count=0
    local local_count=0

    if [ -f "$CATALOG" ]; then
        catalog_count=$(grep -cE '^[0-9]{3}\|' "$CATALOG" 2>/dev/null || echo 0)
    fi

    if [ -d "$TOOLS" ]; then
        local_count=$(find "$TOOLS" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | wc -l | tr -d ' ')
    fi

    echo -e "${C}════════════════════════════════════════════════════════${N}"
    echo -e "${Y}                    TOOLBOX DASHBOARD${N}"
    echo -e "${C}════════════════════════════════════════════════════════${N}"
    echo -e "${W}Catalog tools:${N}       $catalog_count"
    echo -e "${W}Local modules:${N}       $local_count"

    if command -v pkg >/dev/null 2>&1; then
        echo -e "${W}Termux:${N}              Ready"
    else
        echo -e "${W}Termux:${N}              Not detected"
    fi

    if [ -f "$CATALOG" ]; then
        echo -e "${W}Catalog:${N}             Available"
    else
        echo -e "${W}Catalog:${N}             Missing"
    fi

    echo -e "${C}════════════════════════════════════════════════════════${N}"
    echo
}

main() {
    while true
    do
        banner
        dashboard

        echo -e "${Y}[1]${N} Browse Tools"
        echo -e "${Y}[2]${N} Categories"
        echo -e "${Y}[3]${N} Search"
        echo -e "${Y}[4]${N} Install by Number"
        echo -e "${Y}[5]${N} Tool Info"
        echo -e "${Y}[6]${N} Update Termux"
        echo -e "${Y}[7]${N} System Health"
        echo -e "${Y}[8]${N} About"
        echo -e "${Y}[9]${N} Update Tool Catalog"
        echo -e "${Y}[10]${N} Installed Tools"
        echo -e "${Y}[11]${N} Exit"
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
                read -p "Tool number: " id
                tool_info "$id"
                read -p "Press Enter..."
                ;;
            6)
                pkg update
                ;;
            7)
                health_check
                ;;
            8)
                about
                ;;
            9)
                bash "$BASE_DIR/modules/update-catalog.sh"
                read -p "Press Enter..."
                ;;
            10)
                installed_tools
                ;;

            11)
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
