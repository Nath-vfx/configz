#!/usr/bin/env bash

# Configz - Info Command
# Show detailed information about configuration modules

# Source common library
# shellcheck source=../lib/common.sh
source "$CLI_DIR/lib/common.sh"

# =============================================================================
# INFO COMMAND FUNCTIONS
# =============================================================================

show_info_help() {
    cat << EOF
$PROGRAM_NAME info - Show detailed information about configuration modules

USAGE:
    $PROGRAM_NAME info [OPTIONS] <MODULE>

OPTIONS:
    -h, --help          Show this help message
    --json              Output in JSON format
    --no-color          Disable colored output
    --files             Show detailed file listing
    --deps              Show dependency information
    --all               Show all available information

ARGUMENTS:
    MODULE              The module to show information about

EXAMPLES:
    $PROGRAM_NAME info fish                 # Show info about fish module
    $PROGRAM_NAME info --files nvim         # Show nvim info with file listing
    $PROGRAM_NAME info --json starship      # JSON output for scripting
    $PROGRAM_NAME info --all fish           # Show all available information

DESCRIPTION:
    Displays comprehensive information about a configuration module, including:
    - Basic metadata (name, description, version, author)
    - Installation status and paths
    - File listing and sizes
    - Dependencies (system and module)
    - Configuration options
    - Post-installation notes

EOF
}

# Show file listing for module
show_module_files() {
    local module="$1"
    local detailed="$2"
    local source_path="$CONFIG_SOURCE_DIR/$module"

    echo -e "\n${BOLD}Files:${NC}"

    if [[ ! -d "$source_path" ]]; then
        echo -e "  ${DIM}(no files found)${NC}"
        return
    fi

    local total_files=0
    local total_size=0

    while IFS= read -r -d '' file; do
        local relative_path="${file#$source_path/}"

        # Skip configz.toml in file listing
        if [[ "$relative_path" == "configz.toml" ]]; then
            continue
        fi

        if [[ $detailed -eq 1 ]]; then
            local size
            if [[ -f "$file" ]]; then
                if [[ "$OSTYPE" == "darwin"* ]]; then
                    size=$(stat -f "%z" "$file")
                else
                    size=$(stat -c "%s" "$file")
                fi
                total_size=$((total_size + size))

                # Human readable size
                local hr_size
                if [[ $size -lt 1024 ]]; then
                    hr_size="${size}B"
                elif [[ $size -lt 1048576 ]]; then
                    hr_size="$((size / 1024))KB"
                else
                    hr_size="$((size / 1048576))MB"
                fi

                printf "  %-40s %8s\n" "$relative_path" "$hr_size"
            else
                printf "  %-40s %8s\n" "$relative_path/" "(dir)"
            fi
        else
            echo "  $relative_path"
        fi

        ((total_files++))
    done < <(find "$source_path" -type f -print0 | sort -z)

    if [[ $total_files -eq 0 ]]; then
        echo -e "  ${DIM}(no files found)${NC}"
    elif [[ $detailed -eq 1 ]]; then
        echo -e "  ${DIM}────────────────────────────────────────────────────${NC}"

        local hr_total_size
        if [[ $total_size -lt 1024 ]]; then
            hr_total_size="${total_size}B"
        elif [[ $total_size -lt 1048576 ]]; then
            hr_total_size="$((total_size / 1024))KB"
        else
            hr_total_size="$((total_size / 1048576))MB"
        fi

        printf "  %-40s %8s\n" "Total: $total_files files" "$hr_total_size"
    fi
}

# Show dependency information
show_module_dependencies() {
    local module="$1"

    local sys_deps mod_deps
    sys_deps=$(read_module_metadata "$module" "dependencies.system" "")
    mod_deps=$(read_module_metadata "$module" "dependencies.modules" "")

    if [[ -n "$sys_deps" ]] || [[ -n "$mod_deps" ]]; then
        echo -e "\n${BOLD}Dependencies:${NC}"

        if [[ -n "$sys_deps" ]]; then
            echo -e "  ${BOLD}System packages:${NC}"
            local dep_list
            dep_list=$(echo "$sys_deps" | tr ',' ' ' | tr -s ' ')
            for dep in $dep_list; do
                if command -v "$dep" >/dev/null 2>&1; then
                    echo -e "    ${GREEN}✓${NC} $dep"
                else
                    echo -e "    ${RED}✗${NC} $dep ${DIM}(missing)${NC}"
                fi
            done
        fi

        if [[ -n "$mod_deps" ]]; then
            echo -e "  ${BOLD}Module dependencies:${NC}"
            local dep_list
            dep_list=$(echo "$mod_deps" | tr ',' ' ' | tr -s ' ')
            for dep in $dep_list; do
                if is_module_installed "$dep"; then
                    echo -e "    ${GREEN}✓${NC} $dep ${DIM}(installed)${NC}"
                else
                    echo -e "    ${RED}✗${NC} $dep ${DIM}(not installed)${NC}"
                fi
            done
        fi
    else
        echo -e "\n${BOLD}Dependencies:${NC}"
        echo -e "  ${DIM}No dependencies${NC}"
    fi
}

# Show configuration options
show_module_config() {
    local module="$1"
    local config_file="$CONFIG_SOURCE_DIR/$module/configz.toml"

    if [[ ! -f "$config_file" ]]; then
        echo -e "\n${BOLD}Configuration:${NC}"
        echo -e "  ${DIM}Using default configuration (no configz.toml)${NC}"
        return
    fi

    echo -e "\n${BOLD}Configuration:${NC}"

    # Installation type
    local install_type
    install_type=$(read_module_metadata "$module" "installation.type" "copy")
    echo -e "  ${BOLD}Installation type:${NC} $install_type"

    # Custom target
    local custom_target
    custom_target=$(read_module_metadata "$module" "paths.target" "")
    if [[ -n "$custom_target" ]]; then
        echo -e "  ${BOLD}Custom target:${NC} $custom_target"
    fi

    # Backup strategy
    local backup_strategy
    backup_strategy=$(read_module_metadata "$module" "backup.strategy" "auto")
    echo -e "  ${BOLD}Backup strategy:${NC} $backup_strategy"

    # Post-install notes
    local notes
    notes=$(read_module_metadata "$module" "post_install.notes" "")
    if [[ -n "$notes" ]]; then
        echo -e "\n${BOLD}Post-installation notes:${NC}"
        echo "$notes" | while IFS= read -r line; do
            echo "  • $line"
        done
    fi
}

# Show module info in standard format
show_module_info_standard() {
    local module="$1"
    local show_files="$2"
    local show_deps="$3"
    local show_all="$4"
    local no_color="$5"

    if ! module_exists "$module"; then
        log_error "Module '$module' not found"
        return 1
    fi

    # Override colors if requested
    if [[ $no_color -eq 1 ]]; then
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

    local name description icon version author target_path
    name=$(get_module_name "$module")
    description=$(get_module_description "$module")
    icon=$(get_module_icon "$module")
    version=$(get_module_version "$module")
    author=$(get_module_author "$module")
    target_path=$(get_module_target_path "$module")

    # Header
    echo -e "\n${BOLD}${CYAN}${icon} ${name}${NC}"
    echo -e "${DIM}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

    # Basic information
    echo -e "${BOLD}Module ID:${NC}     $module"
    echo -e "${BOLD}Description:${NC}   $description"
    echo -e "${BOLD}Version:${NC}       $version"
    echo -e "${BOLD}Author:${NC}        $author"

    # Paths
    echo -e "\n${BOLD}Paths:${NC}"
    echo -e "  ${BOLD}Source:${NC}  $CONFIG_SOURCE_DIR/$module"
    echo -e "  ${BOLD}Target:${NC}  $target_path"

    # Installation status
    echo -e "\n${BOLD}Status:${NC}"
    if is_module_installed "$module"; then
        echo -e "  ${GREEN}✓ Installed${NC}"

        # Show installation details
        local file_count size modified
        file_count=$(get_file_count "$target_path")
        size=$(get_directory_size "$target_path")
        modified=$(get_last_modified "$target_path")

        echo -e "  ${BOLD}Files:${NC}        $file_count"
        echo -e "  ${BOLD}Size:${NC}         $size"
        echo -e "  ${BOLD}Modified:${NC}     $modified"

        # Check for backups
        local backups
        readarray -t backups < <(find_backups "$target_path")
        if [[ ${#backups[@]} -gt 0 ]]; then
            echo -e "  ${BOLD}Backups:${NC}      ${#backups[@]} found"
        fi
    else
        echo -e "  ${DIM}○ Not installed${NC}"
    fi

    # Show files if requested or if show_all
    if [[ $show_files -eq 1 ]] || [[ $show_all -eq 1 ]]; then
        show_module_files "$module" 1
    fi

    # Show dependencies if requested or if show_all
    if [[ $show_deps -eq 1 ]] || [[ $show_all -eq 1 ]]; then
        show_module_dependencies "$module"
    fi

    # Show configuration if show_all
    if [[ $show_all -eq 1 ]]; then
        show_module_config "$module"
    fi

    echo
}

# Show module info in JSON format
show_module_info_json() {
    local module="$1"
    local show_files="$2"
    local show_deps="$3"
    local show_all="$4"

    if ! module_exists "$module"; then
        echo "{\"error\": \"Module '$module' not found\"}"
        return 1
    fi

    local name description icon version author target_path
    name=$(get_module_name "$module")
    description=$(get_module_description "$module")
    icon=$(get_module_icon "$module")
    version=$(get_module_version "$module")
    author=$(get_module_author "$module")
    target_path=$(get_module_target_path "$module")

    local installed
    installed=$(is_module_installed "$module" && echo true || echo false)

    cat << EOF
{
  "id": "$module",
  "name": "$name",
  "description": "$description",
  "icon": "$icon",
  "version": "$version",
  "author": "$author",
  "installed": $installed,
  "paths": {
    "source": "$CONFIG_SOURCE_DIR/$module",
    "target": "$target_path"
  }
EOF

    if [[ "$installed" == "true" ]]; then
        local file_count size modified
        file_count=$(get_file_count "$target_path")
        size=$(get_directory_size "$target_path")
        modified=$(get_last_modified "$target_path")

        cat << EOF
,
  "installation": {
    "file_count": $file_count,
    "size": "$size",
    "last_modified": "$modified"
  }
EOF
    fi

    # Add files if requested
    if [[ $show_files -eq 1 ]] || [[ $show_all -eq 1 ]]; then
        echo ","
        echo "  \"files\": ["

        local first=true
        while IFS= read -r -d '' file; do
            local relative_path="${file#$CONFIG_SOURCE_DIR/$module/}"

            if [[ "$relative_path" == "configz.toml" ]]; then
                continue
            fi

            if [[ "$first" != "true" ]]; then
                echo ","
            fi
            first=false

            local size=0
            if [[ -f "$file" ]]; then
                if [[ "$OSTYPE" == "darwin"* ]]; then
                    size=$(stat -f "%z" "$file")
                else
                    size=$(stat -c "%s" "$file")
                fi
            fi

            cat << EOF
    {
      "path": "$relative_path",
      "size": $size,
      "type": "$([ -f "$file" ] && echo "file" || echo "directory")"
    }
EOF
        done < <(find "$CONFIG_SOURCE_DIR/$module" -type f -print0 | sort -z)

        echo "  ]"
    fi

    # Add dependencies if requested
    if [[ $show_deps -eq 1 ]] || [[ $show_all -eq 1 ]]; then
        local sys_deps mod_deps
        sys_deps=$(read_module_metadata "$module" "dependencies.system" "")
        mod_deps=$(read_module_metadata "$module" "dependencies.modules" "")

        echo ","
        echo "  \"dependencies\": {"
        echo "    \"system\": ["

        if [[ -n "$sys_deps" ]]; then
            local dep_list
            dep_list=$(echo "$sys_deps" | tr ',' ' ' | tr -s ' ')
            local first=true
            for dep in $dep_list; do
                if [[ "$first" != "true" ]]; then
                    echo ","
                fi
                first=false
                local available
                available=$(command -v "$dep" >/dev/null 2>&1 && echo true || echo false)
                echo "      {\"name\": \"$dep\", \"available\": $available}"
            done
        fi

        echo "    ],"
        echo "    \"modules\": ["

        if [[ -n "$mod_deps" ]]; then
            local dep_list
            dep_list=$(echo "$mod_deps" | tr ',' ' ' | tr -s ' ')
            local first=true
            for dep in $dep_list; do
                if [[ "$first" != "true" ]]; then
                    echo ","
                fi
                first=false
                local installed_dep
                installed_dep=$(is_module_installed "$dep" && echo true || echo false)
                echo "      {\"name\": \"$dep\", \"installed\": $installed_dep}"
            done
        fi

        echo "    ]"
        echo "  }"
    fi

    echo "}"
}

# =============================================================================
# MAIN COMMAND FUNCTION
# =============================================================================

info_main() {
    local module=""
    local json_output=0
    local no_color=0
    local show_files=0
    local show_deps=0
    local show_all=0

    # Parse command-specific options
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_info_help
                exit 0
                ;;
            --json)
                json_output=1
                shift
                ;;
            --no-color)
                no_color=1
                shift
                ;;
            --files)
                show_files=1
                shift
                ;;
            --deps)
                show_deps=1
                shift
                ;;
            --all)
                show_all=1
                shift
                ;;
            -*)
                log_error "Unknown option: $1"
                log_info "Use '$PROGRAM_NAME info --help' for available options"
                exit 1
                ;;
            *)
                if [[ -z "$module" ]]; then
                    module="$1"
                else
                    log_error "Multiple modules specified. Only one module allowed."
                    exit 1
                fi
                shift
                ;;
        esac
    done

    # Check if module specified
    if [[ -z "$module" ]]; then
        log_error "No module specified"
        log_info "Usage: $PROGRAM_NAME info <MODULE>"
        log_info "Available modules:"
        get_available_modules | sed 's/^/  /'
        exit 1
    fi

    # Ensure yq for advanced features
    ensure_yq >/dev/null 2>&1

    # Show information
    if [[ $json_output -eq 1 ]]; then
        show_module_info_json "$module" "$show_files" "$show_deps" "$show_all"
    else
        show_module_info_standard "$module" "$show_files" "$show_deps" "$show_all" "$no_color"
    fi
}
