#!/usr/bin/env bash

# Configz - Backup Command
# Backup current configuration modules

# Source common library
# shellcheck source=../lib/common.sh
source "$CLI_DIR/lib/common.sh"

# Show help message
show_backup_help() {
    cat << EOF
$PROGRAM_NAME backup - Backup configuration modules

USAGE:
    $PROGRAM_NAME backup [OPTIONS] [MODULE...]

OPTIONS:
    -a, --all      Backup all available modules
    -h, --help     Show this help message
    -n, --dry-run  Show what would be backed up without making any changes

ARGUMENTS:
    MODULE...    Specific modules to backup (space-separated). Not used with --all.

EXAMPLES:
    $PROGRAM_NAME backup fish              # Backup fish module
    $PROGRAM_NAME backup fish nvim         # Backup multiple modules
    $PROGRAM_NAME backup --all             # Backup all available modules

DESCRIPTION:
    Creates backups of configuration modules by copying
    their directories to the backup location with timestamps.

    Backups are stored in: ~/.config/configz/backups/

EOF
}

# Main backup function
backup_main() {
    local all_modules=false
    local dry_run=false
    local modules=()

    # Parse options
    while [[ $# -gt 0 ]]; do
        case $1 in
            -a|--all)
                all_modules=true
                shift
                ;;
            -h|--help)
                show_backup_help
                return 0
                ;;
            -n|--dry-run)
                dry_run=true
                shift
                ;;
            -*)
                log_error "Unknown option: $1"
                show_backup_help
                return 1
                ;;
            *)
                modules+=("$1")
                shift
                ;;
        esac
    done
    
    if [[ $dry_run == true ]]; then
        log_info "DRY RUN: No changes will be made"
    fi

    # Show help if no arguments or modules provided
    if [[ $# -eq 0 && ${#modules[@]} -eq 0 && $all_modules == false ]]; then
        show_backup_help
        return 1
    fi

    # Get all modules if --all is specified
    if [[ $all_modules == true ]]; then
        if [[ ${#modules[@]} -gt 0 ]]; then
            log_error "Cannot specify both --all and module names"
            show_backup_help
            return 1
        fi
        
        # Get all modules from the modules directory
        if [[ -d "$CONFIG_SOURCE_DIR" ]]; then
            while IFS= read -r module; do
                if [[ -n "$module" ]]; then
                    modules+=("$module")
                fi
            done < <(find "$CONFIG_SOURCE_DIR" -maxdepth 1 -mindepth 1 -type d -exec basename {} \; 2>/dev/null)
            
            if [[ ${#modules[@]} -eq 0 ]]; then
                log_info "No modules found in $CONFIG_SOURCE_DIR"
                return 0
            fi
        else
            log_error "Modules directory not found: $CONFIG_SOURCE_DIR"
            return 1
        fi
    fi

    # Process each module
    for module in "${modules[@]}"; do
        local source_path="$CONFIG_SOURCE_DIR/$module"
        local timestamp
        timestamp=$(date +"%Y%m%d_%H%M%S")
        local backup_name="${module}.backup.${timestamp}"
        local backup_path="$HOME/.config/configz/backups/$backup_name"
        
        # Check if module exists
        if [[ ! -d "$source_path" ]]; then
            log_error "Module '$module' not found: $source_path"
            continue
        fi
        
        if [[ $dry_run == true ]]; then
            log_info "[DRY RUN] Would create backup: $backup_name"
            log_info "          Source: $source_path"
            log_info "          Destination: $backup_path"
            continue
        fi
        
        # Create backup
        backup_path=$(create_backup "$source_path")
        
        if [[ -n "$backup_path" ]]; then
            log_success "Created backup: $(basename "$backup_path")"
        else
            log_error "Failed to create backup for: $module"
        fi
    done
}
