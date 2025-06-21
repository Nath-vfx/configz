#!/usr/bin/env bash

# Configz - List Command
# Show available configuration modules

# Source common library
# shellcheck source=../lib/common.sh
source "$CLI_DIR/lib/common.sh"

# =============================================================================
# LIST COMMAND FUNCTIONS
# =============================================================================

show_list_help() {
    cat << EOF
$PROGRAM_NAME list - List available configuration modules

USAGE:
    $PROGRAM_NAME list [OPTIONS]

OPTIONS:
    -h, --help        Show this help message
    -a, --all         Show all modules (default)
    -i, --installed   Show only installed modules
    -u, --uninstalled Show only uninstalled modules
    -l, --long        Show detailed information
    --json            Output in JSON format
    --no-color        Disable colored output

EXAMPLES:
    $PROGRAM_NAME list                    # List all modules
    $PROGRAM_NAME list --installed        # Show only installed modules
    $PROGRAM_NAME list --long             # Show detailed information
    $PROGRAM_NAME list --json             # JSON output for scripting

DESCRIPTION:
    Lists all available configuration modules with their installation status.
    Modules are discovered automatically from the config directory.

EOF
}

# List modules in table format
list_modules_table() {
    local filter="$1"  # all, installed, uninstalled
    local long_format="$2"  # 0 or 1
    local no_color="$3"  # 0 or 1

    local modules
    readarray -t modules < <(get_available_modules)

    if [[ ${#modules[@]} -eq 0 ]]; then
        log_info "No modules found in $CONFIG_SOURCE_DIR"
        log_info "Create your first module with: $PROGRAM_NAME init <name>"
        return 0
    fi

    # Header
    if [[ $long_format -eq 1 ]]; then
        echo "ST  ICON NAME                 VERSION    DESCRIPTION                                        PATH"
        echo "--- ---- -------------------- ---------- -------------------------------------------------- ----"
    else
        echo "ST  ICON NAME                 DESCRIPTION"
        echo "--- ---- -------------------- --------------------"
    fi

    local count=0
    for module in "${modules[@]}"; do
        local installed
        if is_module_installed "$module"; then
            installed="yes"
        else
            installed="no"
        fi

        # Apply filter
        case "$filter" in
            installed)
                [[ "$installed" != "yes" ]] && continue
                ;;
            uninstalled)
                [[ "$installed" != "no" ]] && continue
                ;;
        esac

        local name description icon version target_path
        name=$(get_module_name "$module")
        description=$(get_module_description "$module")
        icon=$(get_module_icon "$module")
        version=$(get_module_version "$module")
        target_path=$(get_module_target_path "$module")

        # Status indicator
        local status_icon
        if [[ "$installed" == "yes" ]]; then
            if [[ $no_color -eq 1 ]]; then
                status_icon="✓"
            else
                status_icon="${GREEN}✓${NC}"
            fi
        else
            if [[ $no_color -eq 1 ]]; then
                status_icon="○"
            else
                status_icon="${DIM}○${NC}"
            fi
        fi

        # Truncate long descriptions
        if [[ ${#description} -gt 50 && $long_format -eq 0 ]]; then
            description="${description:0:47}..."
        fi

        if [[ $long_format -eq 1 ]]; then
            echo -e "$status_icon $icon $name $version $description $target_path"
        else
            echo -e "$status_icon $icon $name $description"
        fi

        count=$((count + 1))
    done

    echo
    echo "Total: $count modules"
    if [[ "$filter" != "all" ]]; then
        echo "Filter: $filter"
    fi
}

# List modules in JSON format
list_modules_json() {
    local filter="$1"

    local modules
    readarray -t modules < <(get_available_modules)

    echo "{"
    echo "  \"modules\": ["

    local first=true
    for module in "${modules[@]}"; do
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

        local name description icon version author target_path
        name=$(get_module_name "$module")
        description=$(get_module_description "$module")
        icon=$(get_module_icon "$module")
        version=$(get_module_version "$module")
        author=$(get_module_author "$module")
        target_path=$(get_module_target_path "$module")

        # Add comma separator
        if [[ "$first" != "true" ]]; then
            echo -n ","
        fi
        first=false

        cat << EOF
    {
      "id": "$module",
      "name": "$name",
      "description": "$description",
      "icon": "$icon",
      "version": "$version",
      "author": "$author",
      "installed": $installed,
      "source_path": "$CONFIG_SOURCE_DIR/$module",
      "target_path": "$target_path"
    }
EOF
    done

    echo
    echo "  ],"
    echo "  \"total\": ${#modules[@]},"
    echo "  \"timestamp\": \"$(date -u +"%Y-%m-%dT%H:%M:%SZ")\""
    echo "}"
}

# =============================================================================
# MAIN COMMAND FUNCTION
# =============================================================================

list_main() {
    local filter="all"
    local long_format=0
    local json_output=0
    local no_color=0

    # Parse command-specific options
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_list_help
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
            -l|--long)
                long_format=1
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
                log_info "Use '$PROGRAM_NAME list --help' for available options"
                exit 1
                ;;
            *)
                log_error "Unexpected argument: $1"
                log_info "Use '$PROGRAM_NAME list --help' for usage information"
                exit 1
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
        list_modules_json "$filter"
    else
        if [[ $QUIET -ne 1 ]]; then
            echo -e "${BOLD}${CYAN}Configz Modules${NC}"
            echo -e "${DIM}Source: $CONFIG_SOURCE_DIR${NC}"
            echo -e "${DIM}Target: $TARGET_BASE_DIR${NC}"
            echo
        fi
        list_modules_table "$filter" "$long_format" "$no_color"
    fi
}
