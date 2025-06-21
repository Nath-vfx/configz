#!/usr/bin/env bash

# Configz - Remove Command
# Remove installed configuration modules

# Source common library
# shellcheck source=../lib/common.sh
source "$CLI_DIR/lib/common.sh"

# =============================================================================
# REMOVE COMMAND FUNCTIONS
# =============================================================================

show_remove_help() {
    cat << EOF
$PROGRAM_NAME remove - Remove installed configuration modules

USAGE:
    $PROGRAM_NAME remove [OPTIONS] [MODULE...]

OPTIONS:
    -h, --help          Show this help message
    -f, --force         Force removal without confirmation
    --no-backup         Skip automatic backups before removal
    -n, --dry-run       Show what would be removed without executing
    --clean             Remove backup files as well

ARGUMENTS:
    MODULE...           Specific modules to remove (space-separated)

EXAMPLES:
    $PROGRAM_NAME remove fish                # Remove fish module
    $PROGRAM_NAME remove fish starship       # Remove multiple modules
    $PROGRAM_NAME remove --force fish        # Remove without confirmation
    $PROGRAM_NAME remove --dry-run fish      # Preview removal
    $PROGRAM_NAME remove --clean fish        # Remove and clean backups

DESCRIPTION:
    Removes installed configuration modules by deleting their files from
    the target locations. Creates automatic backups by default unless
    --no-backup is specified.

    This command is currently a stub implementation (v0.2.0-alpha).

EOF
}

# Stub implementation
remove_main() {
    local modules=()
    local force_removal=false
    local clean_backups=false

    # Parse command-specific options
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_remove_help
                exit 0
                ;;
            -f|--force)
                FORCE=1
                force_removal=true
                shift
                ;;
            --no-backup)
                NO_BACKUP=1
                shift
                ;;
            --clean)
                clean_backups=true
                shift
                ;;
            -n|--dry-run)
                DRY_RUN=1
                shift
                ;;
            -*)
                log_error "Unknown option: $1"
                log_info "Use '$PROGRAM_NAME remove --help' for available options"
                exit 1
                ;;
            *)
                modules+=("$1")
                shift
                ;;
        esac
    done

    # Check if modules specified
    if [[ ${#modules[@]} -eq 0 ]]; then
        log_error "No modules specified"
        log_info "Usage: $PROGRAM_NAME remove <MODULE...>"
        log_info "Available modules:"
        get_available_modules | sed 's/^/  /'
        exit 1
    fi

    # Validate modules exist and are installed
    local valid_modules=()
    for module in "${modules[@]}"; do
        if ! module_exists "$module"; then
            log_error "Module '$module' not found"
            continue
        fi

        if ! is_module_installed "$module"; then
            log_warning "Module '$module' is not installed"
            continue
        fi

        valid_modules+=("$module")
    done

    if [[ ${#valid_modules[@]} -eq 0 ]]; then
        log_error "No valid modules to remove"
        exit 1
    fi

    # Show what will be removed
    echo -e "${BOLD}Modules to remove:${NC}"
    for module in "${valid_modules[@]}"; do
        local name icon target_path
        name=$(get_module_name "$module")
        icon=$(get_module_icon "$module")
        target_path=$(get_module_target_path "$module")

        echo -e "  $icon $name"
        echo -e "    ${DIM}Target: $target_path${NC}"
    done
    echo

    # Confirmation
    if [[ $FORCE -eq 0 ]] && [[ $DRY_RUN -eq 0 ]]; then
        if ! confirm "Remove ${#valid_modules[@]} module(s)?"; then
            log_info "Removal cancelled"
            exit 0
        fi
    fi

    # Stub message
    log_warning "Remove command is not fully implemented yet (v0.2.0-alpha)"
    log_info "This is a stub that shows the planned functionality"

    if [[ $DRY_RUN -eq 1 ]]; then
        log_info "Would remove the following:"
        for module in "${valid_modules[@]}"; do
            local target_path
            target_path=$(get_module_target_path "$module")
            log_info "  - $module: $target_path"
        done
    else
        log_info "In the full implementation, this would:"
        log_info "  1. Create backups (unless --no-backup)"
        log_info "  2. Remove target directories"
        log_info "  3. Update registry"
        log_info "  4. Clean backups if requested"
        log_info ""
        log_info "For now, use: rm -rf ~/.config/<module> (manual removal)"
    fi
}
