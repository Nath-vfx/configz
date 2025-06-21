#!/usr/bin/env bash

# Configz - Status Command
# Show installation status of configuration modules

# Source common library
# shellcheck source=../lib/common.sh
source "$CLI_DIR/lib/common.sh"

# =============================================================================
# STATUS COMMAND FUNCTIONS
# =============================================================================

show_status_help() {
    cat << EOF
$PROGRAM_NAME status - Show installation status of configuration modules

USAGE:
    $PROGRAM_NAME status [OPTIONS] [MODULE...]

OPTIONS:
    -h, --help          Show this help message
    -a, --all           Show all modules (default)
    -i, --installed     Show only installed modules
    -u, --uninstalled   Show only uninstalled modules
    -d, --detailed      Show detailed status information
    --json              Output in JSON format
    --no-color          Disable colored output

ARGUMENTS:
    MODULE...           Specific modules to check (space-separated)

EXAMPLES:
    $PROGRAM_NAME status                    # Show status of all modules
    $PROGRAM_NAME status fish starship      # Check specific modules
    $PROGRAM_NAME status --installed        # Show only installed modules
    $PROGRAM_NAME status --detailed         # Show detailed information
    $PROGRAM_NAME status --json             # JSON output for scripting

DESCRIPTION:
    Shows the current installation status of configuration modules, including:
    - Installation status (installed/not installed)
    - Target paths
    - File counts
    - Last modified dates
    - Backup information

EOF
}

# Get file count for a directory
get_file_count() {
    local dir="$1"
    if [[ -d "$dir" ]]; then
        find "$dir" -type f | wc -l
    else
        echo "0"
    fi
}

# Get last modified date
get_last_modified() {
    local path="$1"
    if [[ -e "$path" ]]; then
        if [[ "$OSTYPE" == "darwin"* ]]; then
            stat -f "%Sm" -t "%Y-%m-%d %H:%M:%S" "$path"
        else
            stat -c "%y" "$path" | cut -d. -f1
        fi
    else
        echo "N/A"
    fi
}

# Get directory size
get_directory_size() {
    local dir="$1"
    if [[ -d "$dir" ]]; then
        du -sh "$dir" 2>/dev/null | cut -f1
    else
        echo "0B"
    fi
}

# Check for backups
find_backups() {
    local target_path="$1"
    local backup_pattern="${target_path}.backup.*"
    local backups=()

    # Find backup files/directories
    for backup in ${backup_pattern}; do
        if [[ -e "$backup" ]]; then
            backups+=("$backup")
        fi
    done

    printf '%s\n' "${backups[@]}"
}

# Show status in table format
show_status_table() {
    local filter="$1"
    local detailed="$2"
    local no_color="$3"
    local modules=("${@:4}")

    if [[ ${#modules[@]} -eq 0 ]]; then
        readarray -t modules < <(get_available_modules)
    fi

    if [[ ${#modules[@]} -eq 0 ]]; then
        log_info "No modules found"
        return 0
    fi

    # Header
    if [[ $detailed -eq 1 ]]; then
        printf "%-3s %-4s %-20s %-12s %-6s %-8s %-20s %s\n" \
            "ST" "ICON" "NAME" "STATUS" "FILES" "SIZE" "MODIFIED" "TARGET"
        printf "%-3s %-4s %-20s %-12s %-6s %-8s %-20s %s\n" \
            "---" "----" "--------------------" "------------" "------" "--------" "--------------------" "------"
    else
        printf "%-3s %-4s %-20s %-12s %s\n" \
            "ST" "ICON" "NAME" "STATUS" "TARGET"
        printf "%-3s %-4s %-20s %-12s %s\n" \
            "---" "----" "--------------------" "------------" "------"
    fi

    local installed_count=0
    local total_count=0

    for module in "${modules[@]}"; do
        if ! module_exists "$module"; then
            log_warning "Module '$module' not found, skipping"
            continue
        fi

        local installed
        installed=$(is_module_installed "$module" && echo "yes" || echo "no")

        # Apply filter
        case "$filter" in
            installed)
                [[ "$installed" != "yes" ]] && continue
                ;;
            uninstalled)
                [[ "$installed" != "no" ]] && continue
                ;;
        esac

        local name icon target_path
        name=$(get_module_name "$module")
        icon=$(get_module_icon "$module")
        target_path=$(get_module_target_path "$module")

        # Status display
        local status_icon status_text
        if [[ "$installed" == "yes" ]]; then
            if [[ $no_color -eq 1 ]]; then
                status_icon="✓"
                status_text="installed"
            else
                status_icon="${GREEN}✓${NC}"
                status_text="${GREEN}installed${NC}"
            fi
            installed_count=$((installed_count + 1))
        else
            if [[ $no_color -eq 1 ]]; then
                status_icon="○"
                status_text="not installed"
            else
                status_icon="${DIM}○${NC}"
                status_text="${DIM}not installed${NC}"
            fi
        fi

        if [[ $detailed -eq 1 ]]; then
            local file_count size modified
            file_count=$(get_file_count "$target_path")
            size=$(get_directory_size "$target_path")
            modified=$(get_last_modified "$target_path")

            echo -e "$status_icon $icon $name $status_text $file_count $size $modified $target_path"
        else
            echo -e "$status_icon $icon $name $status_text $target_path"
        fi

        total_count=$((total_count + 1))
    done

    echo
    echo "Summary: $installed_count/$total_count modules installed"

    # Show backup information if any
    if [[ $detailed -eq 1 ]]; then
        echo
        echo -e "${BOLD}Backup Information:${NC}"
        local has_backups=false
        for module in "${modules[@]}"; do
            if ! module_exists "$module"; then
                continue
            fi

            local target_path
            target_path=$(get_module_target_path "$module")
            local backups
            readarray -t backups < <(find_backups "$target_path")

            if [[ ${#backups[@]} -gt 0 ]]; then
                has_backups=true
                local name
                name=$(get_module_name "$module")
                echo "  $name:"
                for backup in "${backups[@]}"; do
                    local backup_date
                    backup_date=$(get_last_modified "$backup")
                    echo "    $(basename "$backup") - $backup_date"
                done
            fi
        done

        if [[ "$has_backups" == "false" ]]; then
            echo "  No backups found"
        fi
    fi
}

# Show status in JSON format
show_status_json() {
    local filter="$1"
    local detailed="$2"
    local modules=("${@:3}")

    if [[ ${#modules[@]} -eq 0 ]]; then
        readarray -t modules < <(get_available_modules)
    fi

    echo "{"
    echo "  \"modules\": ["

    local first=true
    local installed_count=0
    local total_count=0

    for module in "${modules[@]}"; do
        if ! module_exists "$module"; then
            continue
        fi

        local installed
        installed=$(is_module_installed "$module" && echo true || echo false)

        # Apply filter
        case "$filter" in
            installed)
                [[ "$installed" != "true" ]] && continue
                ;;
            uninstalled)
                [[ "$installed" != "false" ]] && continue
                ;;
        esac

        # Add comma separator
        if [[ "$first" != "true" ]]; then
            echo ","
        fi
        first=false

        local name description icon version target_path
        name=$(get_module_name "$module")
        description=$(get_module_description "$module")
        icon=$(get_module_icon "$module")
        version=$(get_module_version "$module")
        target_path=$(get_module_target_path "$module")

        cat << EOF
    {
      "id": "$module",
      "name": "$name",
      "description": "$description",
      "icon": "$icon",
      "version": "$version",
      "installed": $installed,
      "source_path": "$CONFIG_SOURCE_DIR/$module",
      "target_path": "$target_path"
EOF

        if [[ $detailed -eq 1 ]]; then
            local file_count size modified
            file_count=$(get_file_count "$target_path")
            size=$(get_directory_size "$target_path")
            modified=$(get_last_modified "$target_path")

            local backups
            readarray -t backups < <(find_backups "$target_path")

            cat << EOF
,
      "details": {
        "file_count": $file_count,
        "size": "$size",
        "last_modified": "$modified",
        "backups": [
EOF

            local backup_first=true
            for backup in "${backups[@]}"; do
                if [[ "$backup_first" != "true" ]]; then
                    echo ","
                fi
                backup_first=false
                local backup_date
                backup_date=$(get_last_modified "$backup")
                cat << EOF
          {
            "path": "$backup",
            "created": "$backup_date"
          }
EOF
            done

            echo "        ]"
            echo "      }"
        fi

        echo "    }"

        [[ "$installed" == "true" ]] && installed_count=$((installed_count + 1))
        total_count=$((total_count + 1))
    done

    echo
    echo "  ],"
    echo "  \"summary\": {"
    echo "    \"total\": $total_count,"
    echo "    \"installed\": $installed_count,"
    echo "    \"uninstalled\": $((total_count - installed_count))"
    echo "  },"
    echo "  \"timestamp\": \"$(date -u +"%Y-%m-%dT%H:%M:%SZ")\""
    echo "}"
}

# =============================================================================
# MAIN COMMAND FUNCTION
# =============================================================================

status_main() {
    local filter="all"
    local detailed=0
    local json_output=0
    local no_color=0
    local modules=()

    # Parse command-specific options
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_status_help
                exit 0
                ;;
            -a|--all)
                filter="all"
                shift
                ;;
            -i|--installed)
                filter="installed"
                shift
                ;;
            -u|--uninstalled)
                filter="uninstalled"
                shift
                ;;
            -d|--detailed)
                detailed=1
                shift
                ;;
            --json)
                json_output=1
                shift
                ;;
            --no-color)
                no_color=1
                shift
                ;;
            -*)
                log_error "Unknown option: $1"
                log_info "Use '$PROGRAM_NAME status --help' for available options"
                exit 1
                ;;
            *)
                modules+=("$1")
                shift
                ;;
        esac
    done

    # Override colors if requested or if not in terminal
    if [[ $no_color -eq 1 ]] || [[ ! -t 1 ]]; then
        RED=''
        GREEN=''
        YELLOW=''
        BLUE=''
        CYAN=''
        MAGENTA=''
        BOLD=''
        DIM=''
        NC=''
    fi

    # Ensure yq for advanced features
    ensure_yq >/dev/null 2>&1

    # Output format
    if [[ $json_output -eq 1 ]]; then
        show_status_json "$filter" "$detailed" "${modules[@]}"
    else
        if [[ $QUIET -ne 1 ]]; then
            echo -e "${BOLD}${CYAN}Module Status${NC}"
            echo -e "${DIM}Source: $CONFIG_SOURCE_DIR${NC}"
            echo -e "${DIM}Target: $TARGET_BASE_DIR${NC}"
            echo
        fi
        show_status_table "$filter" "$detailed" "$no_color" "${modules[@]}"
    fi
}
