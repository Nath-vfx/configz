#!/usr/bin/env bash

# Configz - Backup Command
# Backup current configuration modules

# Source common library
# shellcheck source=../lib/common.sh
source "$CLI_DIR/lib/common.sh"

# =============================================================================
# BACKUP COMMAND FUNCTIONS
# =============================================================================

show_backup_help() {
    cat << EOF
$PROGRAM_NAME backup - Backup current configuration modules

USAGE:
    $PROGRAM_NAME backup [OPTIONS] [MODULE...]

OPTIONS:
    -h, --help          Show this help message
    -a, --all           Backup all installed modules
    -f, --force         Force backup, overwrite existing backups
    -n, --dry-run       Show what would be backed up without executing
    --compress          Compress backup files (future feature)
    --tag TAG           Add a tag to the backup name

ARGUMENTS:
    MODULE...           Specific modules to backup (space-separated)

EXAMPLES:
    $PROGRAM_NAME backup fish                # Backup fish module
    $PROGRAM_NAME backup --all               # Backup all installed modules
    $PROGRAM_NAME backup --tag "pre-update"  # Backup with custom tag
    $PROGRAM_NAME backup --dry-run fish      # Preview backup

DESCRIPTION:
    Creates backups of currently installed configuration modules by copying
    their target directories to the backup location with timestamps.

    Backups are stored in: ~/.config/configz/backups/

    This command is currently a stub implementation (v0.2.0-alpha).

EOF
}

# Stub implementation
backup_main() {
    local modules=()
    local backup_all=false
    local backup_tag=""

    # Parse command-specific options
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_backup_help
                exit 0
                ;;
            -a|--all)
                backup_all=true
                shift
                ;;
            -f|--force)
                FORCE=1
                shift
                ;;
            --tag)
                if [[ -n "${2:-}" ]]; then
                    backup_tag="$2"
                    shift 2
                else
                    log_error "Option --tag requires a value"
                    exit 1
                fi
                ;;
            -n|--dry-run)
                DRY_RUN=1
                shift
                ;;
            --compress)
                log_info "Compression is not yet implemented"
                shift
                ;;
            -*)
                log_error "Unknown option: $1"
                log_info "Use '$PROGRAM_NAME backup --help' for available options"
                exit 1
                ;;
            *)
                modules+=("$1")
                shift
                ;;
        esac
    done

    # Determine modules to backup
    if [[ $backup_all == true ]]; then
        log_info "Finding all installed modules..."
        # Backup all installed modules
        echo -e "${BOLD}Backing up all installed modules:${NC}"
        # Perform backup
        local successful=0
        local failed=0
        while IFS= read -r module; do
            if is_module_installed "$module"; then
                local name icon
                name=$(get_module_name "$module")
                icon=$(get_module_icon "$module")
                echo "  $icon $name"
                if backup_single_module "$module"; then
                    ((successful++))
                else
                    ((failed++))
                fi
            fi
        done < <(get_available_modules "false")
    fi

    # Check if modules specified
    if [[ ${#modules[@]} -eq 0 ]]; then
        log_error "No modules specified"
        log_info "Usage: $PROGRAM_NAME backup <MODULE...> or --all"
        log_info "Installed modules:"
        while IFS= read -r module; do
            if is_module_installed "$module"; then
                echo "  $module"
            fi
        done < <(get_available_modules)
        exit 1
    fi

    # Validate modules are installed
    local valid_modules=()
    for module in "${modules[@]}"; do
        if ! module_exists "$module"; then
            log_error "Module '$module' not found"
            continue
        fi

        if ! is_module_installed "$module"; then
            log_warning "Module '$module' is not installed, skipping"
            continue
        fi

        valid_modules+=("$module")
    done

    if [[ ${#valid_modules[@]} -eq 0 ]]; then
        log_error "No valid modules to backup"
        exit 1
    fi

    # Show what will be backed up
    local timestamp
    timestamp=$(date +"%Y%m%d_%H%M%S")
    local backup_dir="$HOME/.config/configz/backups"

    echo -e "${BOLD}Modules to backup:${NC}"
    for module in "${valid_modules[@]}"; do
        local name icon target_path backup_name
        name=$(get_module_name "$module")
        icon=$(get_module_icon "$module")
        target_path=$(get_module_target_path "$module")

        if [[ -n "$backup_tag" ]]; then
            backup_name="${module}_${backup_tag}_${timestamp}"
        else
            backup_name="${module}_${timestamp}"
        fi

        echo -e "  $icon $name"
        echo -e "    ${DIM}Source: $target_path${NC}"
        echo -e "    ${DIM}Backup: $backup_dir/$backup_name${NC}"
    done
    echo

    # Stub message
    log_warning "Backup command is not fully implemented yet (v0.2.0-alpha)"
    log_info "This is a stub that shows the planned functionality"

    if [[ $DRY_RUN -eq 1 ]]; then
        log_info "Would create backups for:"
        for module in "${valid_modules[@]}"; do
            local target_path
            target_path=$(get_module_target_path "$module")
            log_info "  - $module: $target_path"
        done
    else
        log_info "In the full implementation, this would:"
        log_info "  1. Create backup directory structure"
        log_info "  2. Copy target directories to backup location"
        log_info "  3. Create metadata files"
        log_info "  4. Update backup registry"
        log_info "  5. Clean old backups if limit exceeded"
        log_info ""
        log_info "Current automatic backups are created during install/remove operations"
    fi
}
