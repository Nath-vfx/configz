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
    -a, --all           Install all available modules (excludes hidden modules)
    -i, --interactive   Interactive selection mode
    -f, --force         Force installation (overwrite existing)
    --no-backup         Skip automatic backups
    --no-symlink        Use copy instead of symlinks (legacy mode)
    --install-hidden    Allow installation of hidden modules (DANGEROUS - requires confirmation)
    --no-deps           Skip dependency checks
    --dry-run           Show what would be installed without executing
    --skip-installed    Skip already installed modules without asking
    --reinstall         Reinstall all modules even if already installed

ARGUMENTS:
    MODULE...           Specific modules to install (space-separated)

EXAMPLES:
    $PROGRAM_NAME install                      # Interactive selection
    $PROGRAM_NAME install fish starship        # Install specific modules
    $PROGRAM_NAME install --all                # Install all modules (excludes hidden)
    $PROGRAM_NAME install --no-backup fish     # Install without backup
    $PROGRAM_NAME install --no-symlink fish    # Install using copy mode
    $PROGRAM_NAME install --dry-run fish       # Preview installation
    
    # DANGEROUS OPERATIONS (hidden modules):
    $PROGRAM_NAME install --install-hidden .git    # Install hidden module (requires confirmation)
    $PROGRAM_NAME install --all --install-hidden   # Install ALL including hidden (VERY DANGEROUS)

DESCRIPTION:
    Installs configuration modules by creating symlinks from the source directory
    to their target locations. This is the new default behavior that allows for
    easy updates and management. Use --no-symlink to use the legacy copy mode.
    
    Creates automatic backups by default when overwriting existing configurations.

    SECURITY: Hidden modules (starting with .) are excluded by default for security.
    Use --install-hidden flag with extreme caution as hidden configurations may
    contain sensitive data or system-critical settings.

    If no modules are specified, enters interactive selection mode.

EOF
}

# Interactive module selection
interactive_selection() {
    local modules
    readarray -t modules < <(get_available_modules "false")

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
    log_debug "Starting installation of module: $module"

    # Check if module exists
    if ! module_exists "$module"; then
        log_error "Module '$module' not found"
        return 1
    fi

    # Debug: Afficher les valeurs des variables globales
    log_debug "FORCE=$FORCE, SKIP_INSTALLED=$SKIP_INSTALLED, REINSTALL=$REINSTALL"
    
    # Check if already installed
    if is_module_installed "$module" && [[ $FORCE -eq 0 ]]; then
        log_debug "Module '$module' is already installed and FORCE=$FORCE"
        
        if [[ $SKIP_INSTALLED -eq 1 ]]; then
            log_info "Module '$module' is already installed, skipping (--skip-installed)"
            return 0
        elif [[ $REINSTALL -eq 1 ]]; then
            log_info "Module '$module' is already installed, reinstalling (--reinstall)"
        else
            log_warning "Module '$module' is already installed"
            if ! confirm "Reinstall module '$module'?"; then
                log_info "Skipping module '$module'"
                return 0
            fi
        fi
    else
        log_debug "Module '$module' is not installed or FORCE is enabled"
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
    else
        log_error "Failed to install module '$module'"
        return 1  # On retourne 1 uniquement en cas d'erreur d'installation
    fi
    return 0
}

# Install multiple modules
install_modules() {
    local modules=("$@")
    local successful=0
    local failed=0

    log_info "Installing ${#modules[@]} modules..."
    log_debug "Modules to install: ${modules[*]}"
    log_debug "Number of modules: ${#modules[@]}"
    log_debug "Module list: ${modules[*]}"
    
    # Debug: Afficher les variables globales
    log_debug "[install_modules] Global variables:"
    log_debug "  SKIP_INSTALLED=$SKIP_INSTALLED"
    log_debug "  REINSTALL=$REINSTALL"
    log_debug "  FORCE=$FORCE"
    log_debug "  DRY_RUN=$DRY_RUN"
    echo

    local module_count=0
    log_debug "Starting module processing loop"
    log_debug "Modules array content: ${modules[*]}"
    log_debug "Modules array length: ${#modules[@]}"
    
    for module in "${modules[@]}"; do
        module_count=$((module_count + 1))
        log_debug "Processing module $module_count/${#modules[@]}: $module"
        log_debug "Module value: '$module'"
        
        if [[ -z "$module" ]]; then
            log_warning "Empty module name encountered, skipping..."
            continue
        fi
        
        if install_single_module "$module"; then
            log_debug "Successfully processed module: $module"
            ((successful++))
        else
            log_error "Failed to process module: $module"
            ((failed++))
        fi
        echo
    done

    # Résumé
    echo
    echo -e "${BOLD}Installation Summary:${NC}"
    log_debug "Processed $module_count modules in total"
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
    # Vérification de la variable d'environnement
    if [[ -z "$CONFIG_SOURCE_DIR" ]]; then
        log_error "CONFIG_SOURCE_DIR n'est pas définie !"
        return 1
    fi
    if [[ ! -d "$CONFIG_SOURCE_DIR" ]]; then
        log_error "Le dossier source des modules n'existe pas : $CONFIG_SOURCE_DIR"
        return 1
    fi
    local modules
    
    # Get modules based on ALLOW_HIDDEN flag
    if [[ ${ALLOW_HIDDEN:-0} -eq 1 ]]; then
        readarray -t modules < <(get_available_modules "true")
        log_warning "Including hidden modules (DANGEROUS operation requested)"
    else
        readarray -t modules < <(get_available_modules "false")
        log_info "Excluding hidden modules for security (use --install-hidden to include)"
    fi
    # Debug : afficher la liste des modules trouvés
    echo "[DEBUG] Modules trouvés : ${modules[*]}"
    if [[ ${#modules[@]} -eq 0 ]]; then
        if [[ ${ALLOW_HIDDEN:-0} -eq 1 ]]; then
            log_error "No modules found to install (including hidden)"
        else
            log_error "No modules found to install"
            log_info "Tip: Use --install-hidden to include hidden modules (DANGEROUS)"
        fi
        return 1
    fi

    # Check for hidden modules and require confirmation
    local hidden_modules=()
    for module in "${modules[@]}"; do
        if [[ "$module" =~ ^\..*$ ]]; then
            hidden_modules+=("$module")
        fi
    done
    
    if [[ ${#hidden_modules[@]} -gt 0 ]]; then
        if [[ ${ALLOW_HIDDEN:-0} -ne 1 ]]; then
            log_error "Hidden modules detected but --install-hidden flag not provided"
            log_error "Hidden modules found: ${hidden_modules[*]}"
            log_info "Use --install-hidden flag to install hidden modules (DANGEROUS)"
            return 1
        fi
        
        # Double confirmation for hidden modules
        if ! confirm_hidden_installation "${hidden_modules[@]}"; then
            return 1
        fi
    fi

    echo -e "${BOLD}Installing all available modules:${NC}"
    for module in "${modules[@]}"; do
        local name icon
        name=$(get_module_name "$module")
        icon=$(get_module_icon "$module")
        if [[ "$module" =~ ^\..*$ ]]; then
            echo -e "  ${RED}$icon $name (HIDDEN)${NC}"
        else
            echo -e "  $icon $name"
        fi
    done
    echo

    if [[ $FORCE -eq 0 ]] && ! confirm "Install all ${#modules[@]} modules?"; then
        log_info "Installation cancelled"
        return 1
    fi

    # Appel à install_modules avec tous les modules
    log_debug "Calling install_modules with ${#modules[@]} modules: ${modules[*]}"
    if ! install_modules "${modules[@]}"; then
        log_error "Failed to install some modules"
        return 1
    fi
    return 0
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

# Double confirmation for hidden module installation
confirm_hidden_installation() {
    local modules=("$@")
    
    echo -e "${RED}${BOLD}⚠️  DANGER: Installing Hidden Modules ⚠️${NC}"
    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${YELLOW}You are about to install HIDDEN configuration modules:${NC}"
    echo
    
    for module in "${modules[@]}"; do
        if [[ "$module" =~ ^\..*$ ]]; then
            local name icon
            name=$(get_module_name "$module")
            icon=$(get_module_icon "$module")
            echo -e "  ${RED}🔥${NC} ${BOLD}$icon $name${NC} ${RED}(HIDDEN)${NC}"
        fi
    done
    
    echo
    echo -e "${RED}${BOLD}WARNING:${NC} Hidden modules may contain:"
    echo -e "  ${YELLOW}• Sensitive system configurations${NC}"
    echo -e "  ${YELLOW}• Security-critical settings${NC}"
    echo -e "  ${YELLOW}• Private or personal data${NC}"
    echo -e "  ${YELLOW}• Configurations meant to stay private${NC}"
    echo
    echo -e "${RED}${BOLD}RISKS:${NC}"
    echo -e "  ${RED}• May expose sensitive information${NC}"
    echo -e "  ${RED}• May break system security${NC}"
    echo -e "  ${RED}• May cause unintended side effects${NC}"
    echo
    echo -e "${BOLD}This operation is performed AT YOUR OWN RISK!${NC}"
    echo
    
    # First confirmation
    if ! confirm "${RED}Do you REALLY want to install these HIDDEN modules?${NC}"; then
        log_info "Installation cancelled for security"
        return 1
    fi
    
    echo
    echo -e "${RED}${BOLD}FINAL WARNING:${NC} You are installing HIDDEN modules!"
    
    # Second confirmation with typed confirmation
    read -p "Type 'INSTALL HIDDEN MODULES' to confirm (case sensitive): " confirmation
    if [[ "$confirmation" != "INSTALL HIDDEN MODULES" ]]; then
        log_error "Confirmation failed. Installation cancelled for security."
        return 1
    fi
    
    echo
    log_warning "Proceeding with hidden module installation at user's own risk..."
    return 0
}

# =============================================================================
# MAIN COMMAND FUNCTION
# =============================================================================

install_main() {
    local modules=()
    local install_all=0
    local interactive=0
    local skip_deps=0
    local allow_hidden=0
    local skip_installed=0
    local reinstall=0

    # First pass: collect all arguments
    local args=("$@")
    local processed_args=()
    
    # Process all arguments to collect options and modules
    log_debug "Processing arguments: ${args[*]}"
    while [[ ${#args[@]} -gt 0 ]]; do
        log_debug "Current argument: ${args[0]}"
        case ${args[0]} in
            -h|--help)
                show_install_help
                exit 0
                ;;
            -a|--all)
                install_all=1
                ;;
            -i|--interactive)
                interactive=1
                ;;
            -f|--force)
                FORCE=1
                ;;
            --no-backup)
                NO_BACKUP=1
                ;;
            --no-symlink)
                NO_SYMLINK=1
                ;;
            --install-hidden)
                allow_hidden=1
                ;;
            --skip-installed)
                skip_installed=1
                ;;
            --reinstall)
                reinstall=1
                ;;
            --no-deps)
                skip_deps=1
                ;;
            --dry-run)
                DRY_RUN=1
                ;;
            -*)
                log_error "Unknown option: ${args[0]}"
                log_info "Use '$PROGRAM_NAME install --help' for available options"
                exit 1
                ;;
            *)
                # This is a module name, add it to the modules array
                log_debug "Adding module: ${args[0]}"
                modules+=("${args[0]}")
                ;;
        esac
        # Shift the current argument out of the array
        log_debug "Shifting args: ${args[*]}"
        args=("${args[@]:1}")
        log_debug "Args after shift: ${args[*]}"
    done

    # Export variables for use in functions
    export SKIP_DEPS=$skip_deps
    export ALLOW_HIDDEN=$allow_hidden
    export SKIP_INSTALLED=$skip_installed
    export REINSTALL=$reinstall
    
    # Debug: Afficher les valeurs des variables
    log_debug "Variables after processing arguments:"
    log_debug "  SKIP_DEPS=$SKIP_DEPS"
    log_debug "  ALLOW_HIDDEN=$ALLOW_HIDDEN"
    log_debug "  SKIP_INSTALLED=$SKIP_INSTALLED"
    log_debug "  REINSTALL=$REINSTALL"
    log_debug "  FORCE=$FORCE"
    log_debug "  modules=(${modules[*]})"
    
    # Log flags if set
    if [[ $skip_installed -eq 1 ]]; then
        log_info "--skip-installed: Will skip already installed modules"
    fi
    if [[ $reinstall -eq 1 ]]; then
        log_info "--reinstall: Will reinstall all specified modules"
    fi
    if [[ $skip_installed -eq 1 && $reinstall -eq 1 ]]; then
        log_error "Cannot use --skip-installed and --reinstall together"
        exit 1
    fi

    # Ensure yq for advanced features
    ensure_yq >/dev/null 2>&1

    # Debug: Afficher les modules avant la validation
    log_debug "[install_main] Modules before validation: ${modules[*]}"
    log_debug "[install_main] Number of modules: ${#modules[@]}"
    
    # Determine installation mode
    if [[ $install_all -eq 1 ]]; then
        install_all_modules
    elif [[ ${#modules[@]} -gt 0 ]]; then
        # Validate modules exist
        local invalid_modules=()
        local hidden_modules=()
        
        log_debug "[install_main] Validating modules..."
        for module in "${modules[@]}"; do
            log_debug "[install_main] Validating module: $module"
            if ! module_exists "$module"; then
                log_debug "[install_main] Module not found: $module"
                invalid_modules+=("$module")
            elif [[ "$module" =~ ^\..*$ ]]; then
                log_debug "[install_main] Hidden module found: $module"
                hidden_modules+=("$module")
            else
                log_debug "[install_main] Module is valid: $module"
            fi
        done

        # Afficher les modules après validation
        log_debug "[install_main] After validation - Modules to install: ${modules[*]}"
        log_debug "[install_main] After validation - Number of modules: ${#modules[@]}"
        
        if [[ ${#invalid_modules[@]} -gt 0 ]]; then
            log_error "Invalid modules: ${invalid_modules[*]}"
            log_info "Available modules:"
            get_available_modules "false" | sed 's/^/  /'
            if [[ ${#hidden_modules[@]} -gt 0 ]]; then
                echo
                log_info "Hidden modules are available but require --install-hidden flag:"
                get_available_modules "true" | grep "^\." | sed 's/^/  /' || true
            fi
            exit 1
        fi
        
        # Check for hidden modules
        if [[ ${#hidden_modules[@]} -gt 0 ]]; then
            if [[ ${ALLOW_HIDDEN:-0} -ne 1 ]]; then
                log_error "Hidden modules cannot be installed without --install-hidden flag"
                log_error "Hidden modules specified: ${hidden_modules[*]}"
                echo
                log_warning "Hidden modules contain sensitive configurations and should remain private."
                log_info "If you really need to install hidden modules, use:"
                echo "  $PROGRAM_NAME install --install-hidden ${hidden_modules[*]}"
                echo
                log_error "Installation cancelled for security reasons"
                exit 1
            fi
            
            # Double confirmation for hidden modules
            if ! confirm_hidden_installation "${hidden_modules[@]}"; then
                exit 1
            fi
        fi

        # Créer un nouveau tableau pour s'assurer que les modules sont correctement passés
        local install_modules_array=("${modules[@]}")
        log_debug "[install_main] Calling install_modules with: ${#install_modules_array[@]} modules"
        log_debug "[install_main] Modules to install: ${install_modules_array[*]}"
        
        if [[ $DRY_RUN -eq 1 ]]; then
            preview_installation "${install_modules_array[@]}"
        else
            # Appeler install_modules avec le tableau d'arguments
            if ! install_modules "${install_modules_array[@]}"; then
                log_error "Failed to install one or more modules"
                return 1
            fi
        fi
    elif [[ $interactive -eq 1 ]]; then
        interactive_selection
    else
        # Default to interactive if no modules specified
        interactive_selection
    fi
}
