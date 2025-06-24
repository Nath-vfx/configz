#!/usr/bin/env bash

# Configz - Install Command
# Install configuration modules

# Source common library
# shellcheck source=../lib/common.sh
source "$CLI_DIR/lib/common.sh"

# =============================================================================
# INSTALL COMMAND FUNCTIONS
# =============================================================================

show_install_help() {
    cat << EOF
$PROGRAM_NAME install - Install configuration modules

USAGE:
    $PROGRAM_NAME install [OPTIONS] [MODULE...]

OPTIONS:
    -h, --help          Show this help message
    -a, --all           Install all available modules
    -i, --interactive   Interactive selection mode
    -f, --force         Force installation (overwrite existing)
    --no-backup         Skip automatic backups
    --no-symlink        Use copy instead of symlinks (legacy mode)
    --no-deps           Skip dependency checks
    --dry-run           Show what would be installed without executing

ARGUMENTS:
    MODULE...           Specific modules to install (space-separated)

EXAMPLES:
    $PROGRAM_NAME install                      # Interactive selection
    $PROGRAM_NAME install fish starship        # Install specific modules
    $PROGRAM_NAME install --all                # Install all modules
    $PROGRAM_NAME install --no-backup fish     # Install without backup
    $PROGRAM_NAME install --no-symlink fish    # Install using copy mode
    $PROGRAM_NAME install --dry-run fish       # Preview installation

DESCRIPTION:
    Installs configuration modules by creating symlinks from the source directory
    to their target locations. This is the new default behavior that allows for
    easy updates and management. Use --no-symlink to use the legacy copy mode.
    
    Creates automatic backups by default when overwriting existing configurations.

    If no modules are specified, enters interactive selection mode.

EOF
}

# Interactive module selection
interactive_selection() {
    local modules
    readarray -t modules < <(get_available_modules)

    if [[ ${#modules[@]} -eq 0 ]]; then
        log_error "No modules found"
        return 1
    fi

    echo -e "${BOLD}${CYAN}Interactive Module Selection${NC}"
    echo -e "${DIM}Use space to select, enter to confirm${NC}"
    echo

    local selected=()
    local current=0

    while true; do
        clear
        echo -e "${BOLD}${CYAN}Select modules to install:${NC}"
        echo -e "${DIM}↑/↓ navigate, SPACE select, ENTER confirm, q quit${NC}"
        echo

        # Display modules
        for i in "${!modules[@]}"; do
            local module="${modules[$i]}"
            local name icon installed_status
            name=$(get_module_name "$module")
            icon=$(get_module_icon "$module")

            if is_module_installed "$module"; then
                installed_status="${GREEN}[installed]${NC}"
            else
                installed_status="${DIM}[not installed]${NC}"
            fi

            local selected_mark=""
            if [[ " ${selected[*]} " =~ " ${module} " ]]; then
                selected_mark="${GREEN}[✓]${NC}"
            else
                selected_mark="[ ]"
            fi

            local line_prefix=""
            if [[ $i -eq $current ]]; then
                line_prefix="${CYAN}▶${NC} "
            else
                line_prefix "  "
            fi

            printf "%s%s %s %-20s %s %s\n" \
                "$line_prefix" "$selected_mark" "$icon" "$name" \
                "$(get_module_description "$module" | cut -c1-40)" "$installed_status"
        done

        echo
        echo -e "${BOLD}Selected:${NC} ${#selected[@]} modules"

        # Read input
        read -n 1 -s key
        case "$key" in
            $'\x1b')  # ESC sequence
                read -n 2 -s rest
                case "$rest" in
                    '[A') # Up arrow
                        ((current > 0)) && ((current--))
                        ;;
                    '[B') # Down arrow
                        ((current < ${#modules[@]} - 1)) && ((current++))
                        ;;
                esac
                ;;
            ' ')  # Space - toggle selection
                local module="${modules[$current]}"
                if [[ " ${selected[*]} " =~ " ${module} " ]]; then
                    # Remove from selection
                    local new_selected=()
                    for sel in "${selected[@]}"; do
                        [[ "$sel" != "$module" ]] && new_selected+=("$sel")
                    done
                    selected=("${new_selected[@]}")
                else
                    # Add to selection
                    selected+=("$module")
                fi
                ;;
            $'\n'|$'\r')  # Enter - confirm
                break
                ;;
            'q'|'Q')  # Quit
                echo
                log_info "Installation cancelled"
                return 1
                ;;
            'a'|'A')  # Select all
                selected=("${modules[@]}")
                ;;
            'n'|'N')  # Select none
                selected=()
                ;;
        esac
    done

    clear
    if [[ ${#selected[@]} -eq 0 ]]; then
        log_info "No modules selected"
        return 1
    fi

    echo -e "${BOLD}Selected modules:${NC}"
    for module in "${selected[@]}"; do
        local name icon
        name=$(get_module_name "$module")
        icon=$(get_module_icon "$module")
        echo "  $icon $name"
    done
    echo

    if ! confirm "Install these modules?"; then
        log_info "Installation cancelled"
        return 1
    fi

    # Install selected modules
    install_modules "${selected[@]}"
}

# Install single module
install_single_module() {
    local module="$1"

    log_info "Installing module: $module"

    # Check if module exists
    if ! module_exists "$module"; then
        log_error "Module '$module' not found"
        return 1
    fi

    # Check if already installed
    if is_module_installed "$module" && [[ $FORCE -eq 0 ]]; then
        log_warning "Module '$module' is already installed"
        if ! confirm "Reinstall module '$module'?"; then
            log_info "Skipping module '$module'"
            return 0
        fi
    fi

    # Check dependencies
    if [[ $SKIP_DEPS -eq 0 ]]; then
        if ! check_system_dependencies "$module"; then
            log_error "System dependency check failed for module '$module'"
            return 1
        fi

        if ! check_module_dependencies "$module"; then
            log_error "Module dependency check failed for module '$module'"
            return 1
        fi
    fi

    # Install the module
    if install_module_files "$module"; then
        # Show post-install notes if any
        local notes
        notes=$(read_module_metadata "$module" "post_install.notes" "")
        if [[ -n "$notes" ]]; then
            echo -e "\n${BOLD}Post-installation notes for $module:${NC}"
            echo "$notes" | while IFS= read -r line; do
                echo "  • $line"
            done
            echo
        fi
        return 0
    else
        log_error "Failed to install module '$module'"
        return 1
    fi
}

# Install multiple modules
install_modules() {
    local modules=("$@")
    local successful=0
    local failed=0

    log_info "Installing ${#modules[@]} modules..."
    echo

    for module in "${modules[@]}"; do
        if install_single_module "$module"; then
            ((successful++))
        else
            ((failed++))
        fi
        echo
    done

    # Summary
    echo -e "${BOLD}Installation Summary:${NC}"
    echo -e "  ${GREEN}Successful:${NC} $successful"
    if [[ $failed -gt 0 ]]; then
        echo -e "  ${RED}Failed:${NC} $failed"
    fi
    echo -e "  ${BOLD}Total:${NC} ${#modules[@]}"

    if [[ $failed -gt 0 ]]; then
        return 1
    fi
    return 0
}

# Install all modules
install_all_modules() {
    local modules
    readarray -t modules < <(get_available_modules)

    if [[ ${#modules[@]} -eq 0 ]]; then
        log_error "No modules found to install"
        return 1
    fi

    echo -e "${BOLD}Installing all available modules:${NC}"
    for module in "${modules[@]}"; do
        local name icon
        name=$(get_module_name "$module")
        icon=$(get_module_icon "$module")
        echo "  $icon $name"
    done
    echo

    if [[ $FORCE -eq 0 ]] && ! confirm "Install all ${#modules[@]} modules?"; then
        log_info "Installation cancelled"
        return 1
    fi

    install_modules "${modules[@]}"
}

# Preview installation
preview_installation() {
    local modules=("$@")

    echo -e "${BOLD}Installation Preview:${NC}"
    echo

    for module in "${modules[@]}"; do
        if ! module_exists "$module"; then
            log_error "Module '$module' not found"
            continue
        fi

        local name icon target_path
        name=$(get_module_name "$module")
        icon=$(get_module_icon "$module")
        target_path=$(get_module_target_path "$module")

        echo -e "${BOLD}$icon $name${NC}"
        echo -e "  ${DIM}Target: $target_path${NC}"

        # Check current status
        if is_module_installed "$module"; then
            echo -e "  ${YELLOW}Status: Currently installed (would be updated)${NC}"
            if [[ $NO_BACKUP -eq 0 ]]; then
                if [[ $NO_SYMLINK -eq 1 ]]; then
                    echo -e "  ${BLUE}Action: Backup existing + Install (copy)${NC}"
                else
                    echo -e "  ${BLUE}Action: Backup existing + Install (symlink)${NC}"
                fi
            else
                if [[ $NO_SYMLINK -eq 1 ]]; then
                    echo -e "  ${BLUE}Action: Overwrite existing (copy)${NC}"
                else
                    echo -e "  ${BLUE}Action: Overwrite existing (symlink)${NC}"
                fi
            fi
        else
            echo -e "  ${GREEN}Status: Not installed${NC}"
            if [[ $NO_SYMLINK -eq 1 ]]; then
                echo -e "  ${BLUE}Action: Install (copy)${NC}"
            else
                echo -e "  ${BLUE}Action: Install (symlink)${NC}"
            fi
        fi

        # Show files
        echo -e "  ${BOLD}Files:${NC}"
        while IFS= read -r -d '' file; do
            local relative_path="${file#$CONFIG_SOURCE_DIR/$module/}"
            if [[ "$relative_path" != "configz.toml" ]]; then
                echo -e "    ${DIM}$relative_path${NC}"
            fi
        done < <(find "$CONFIG_SOURCE_DIR/$module" -type f -print0)

        echo
    done
}

# =============================================================================
# MAIN COMMAND FUNCTION
# =============================================================================

install_main() {
    local modules=()
    local install_all=0
    local interactive=0
    local skip_deps=0

    # Parse command-specific options
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_install_help
                exit 0
                ;;
            -a|--all)
                install_all=1
                shift
                ;;
            -i|--interactive)
                interactive=1
                shift
                ;;
            -f|--force)
                FORCE=1
                shift
                ;;
            --no-backup)
                NO_BACKUP=1
                shift
                ;;
            --no-symlink)
                NO_SYMLINK=1
                shift
                ;;
            --no-deps)
                skip_deps=1
                shift
                ;;
            --dry-run)
                DRY_RUN=1
                shift
                ;;
            -*)
                log_error "Unknown option: $1"
                log_info "Use '$PROGRAM_NAME install --help' for available options"
                exit 1
                ;;
            *)
                modules+=("$1")
                shift
                ;;
        esac
    done

    # Export skip_deps for use in functions
    SKIP_DEPS=$skip_deps

    # Ensure yq for advanced features
    ensure_yq >/dev/null 2>&1

    # Determine installation mode
    if [[ $install_all -eq 1 ]]; then
        if [[ $DRY_RUN -eq 1 ]]; then
            readarray -t all_modules < <(get_available_modules)
            preview_installation "${all_modules[@]}"
        else
            install_all_modules
        fi
    elif [[ ${#modules[@]} -gt 0 ]]; then
        # Validate modules exist
        local invalid_modules=()
        for module in "${modules[@]}"; do
            if ! module_exists "$module"; then
                invalid_modules+=("$module")
            fi
        done

        if [[ ${#invalid_modules[@]} -gt 0 ]]; then
            log_error "Invalid modules: ${invalid_modules[*]}"
            log_info "Available modules:"
            get_available_modules | sed 's/^/  /'
            exit 1
        fi

        if [[ $DRY_RUN -eq 1 ]]; then
            preview_installation "${modules[@]}"
        else
            install_modules "${modules[@]}"
        fi
    elif [[ $interactive -eq 1 ]]; then
        interactive_selection
    else
        # Default to interactive if no modules specified
        interactive_selection
    fi
}
