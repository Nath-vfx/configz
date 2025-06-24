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
    --no-symlink        Assume copy mode instead of symlinks
    -n, --dry-run       Show what would be removed without executing
    --clean             Remove backup files as well

ARGUMENTS:
    MODULE...           Specific modules to remove (space-separated)

EXAMPLES:
    $PROGRAM_NAME remove fish                # Remove fish module
    $PROGRAM_NAME remove fish starship       # Remove multiple modules
    $PROGRAM_NAME remove --force fish        # Remove without confirmation
    $PROGRAM_NAME remove --no-symlink fish   # Remove assuming copy mode
    $PROGRAM_NAME remove --dry-run fish      # Preview removal
    $PROGRAM_NAME remove --clean fish        # Remove and clean backups

DESCRIPTION:
    Removes installed configuration modules by deleting their symlinks or 
    copied files from the target locations. Automatically detects whether 
    modules were installed as symlinks or copies. Use --no-symlink to force
    copy mode behavior.
    
    Creates automatic backups by default unless --no-backup is specified.

    Supports dry-run mode to preview changes before execution.

EOF
}

# Remove a single module
remove_single_module() {
    local module="$1"
    local target_path
    target_path=$(get_module_target_path "$module")

    log_info "Removing module: $module"

    # Check if module is actually installed
    if [[ ! -d "$target_path" ]]; then
        log_warning "Module '$module' target directory not found: $target_path"
        return 1
    fi

    # Create backup before removal unless disabled
    if [[ $NO_BACKUP -eq 0 ]]; then
        local backup_path
        backup_path=$(create_backup "$target_path")
        if [[ -n "$backup_path" ]]; then
            log_info "Created backup: $(basename "$backup_path")"
        fi
    fi

    # Remove the target directory
    if [[ $DRY_RUN -eq 1 ]]; then
        log_info "Would remove: $target_path"
    else
        if rm -rf "$target_path"; then
            log_success "Removed: $target_path"
        else
            log_error "Failed to remove: $target_path"
            return 1
        fi
    fi

    return 0
}

# Clean backup files for a module
clean_module_backups() {
    local module="$1"
    local target_path
    target_path=$(get_module_target_path "$module")
    local backup_pattern="${target_path}.backup.*"

    log_info "Cleaning backups for module: $module"

    local cleaned_count=0
    for backup in ${backup_pattern}; do
        if [[ -e "$backup" ]]; then
            if [[ $DRY_RUN -eq 1 ]]; then
                log_info "Would remove backup: $backup"
            else
                if rm -rf "$backup"; then
                    log_info "Removed backup: $(basename "$backup")"
                    cleaned_count=$((cleaned_count + 1))
                else
                    log_warning "Failed to remove backup: $backup"
                fi
            fi
        fi
    done

    if [[ $cleaned_count -eq 0 ]]; then
        log_info "No backups found for module: $module"
    else
        log_success "Cleaned $cleaned_count backup(s) for module: $module"
    fi
}

# Update registry after removal
update_removal_registry() {
    local removed_modules=("$@")
    local registry_file
    registry_file="$(dirname "$CONFIG_SOURCE_DIR")/registry.json"

    if [[ ! -f "$registry_file" ]]; then
        return 0
    fi

    if [[ $DRY_RUN -eq 1 ]]; then
        log_info "Would update registry: $registry_file"
        return 0
    fi

    # Update registry with removal information
    if command -v jq >/dev/null 2>&1; then
        local temp_file
        temp_file=$(mktemp)

        # Update last_updated and add removal info
        jq --argjson modules "$(printf '%s\n' "${removed_modules[@]}" | jq -R . | jq -s .)" \
           --arg date "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" \
           '.last_updated = $date | .last_removal_date = $date | .last_removed_modules = $modules' \
           "$registry_file" > "$temp_file" && mv "$temp_file" "$registry_file"

        log_debug "Updated registry with removal information"
    fi
}

# Full implementation
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
            --no-symlink)
                NO_SYMLINK=1
                shift
                ;;
            -n|--dry-run)
                DRY_RUN=1
                shift
                ;;
            --clean)
                clean_backups=true
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
        log_info "Installed modules:"
        while IFS= read -r module; do
            if is_module_installed "$module"; then
                local name icon
                name=$(get_module_name "$module")
                icon=$(get_module_icon "$module")
                echo "  $icon $name ($module)"
            fi
        done < <(get_available_modules)
        exit 1
    fi

    # Validate modules exist and are installed
    local valid_modules=()
    local warning_count=0

    for module in "${modules[@]}"; do
        if ! module_exists "$module"; then
            log_error "Module '$module' not found"
            warning_count=$((warning_count + 1))
            continue
        fi

        if ! is_module_installed "$module"; then
            log_warning "Module '$module' is not installed"
            warning_count=$((warning_count + 1))
            continue
        fi

        valid_modules+=("$module")
    done

    if [[ ${#valid_modules[@]} -eq 0 ]]; then
        log_error "No valid modules to remove"
        exit 1
    fi

    if [[ $warning_count -gt 0 && ${#valid_modules[@]} -gt 0 ]]; then
        log_warning "Some modules were skipped, continuing with valid modules"
    fi

    # Show what will be removed
    echo -e "${BOLD}Modules to remove:${NC}"
    for module in "${valid_modules[@]}"; do
        local name icon target_path file_count
        name=$(get_module_name "$module")
        icon=$(get_module_icon "$module")
        target_path=$(get_module_target_path "$module")
        file_count=$(get_file_count "$target_path")

        echo -e "  $icon $name"
        echo -e "    ${DIM}Target: $target_path${NC}"
        echo -e "    ${DIM}Files: $file_count${NC}"

        # Show if backups exist
        local backup_count=0
        local backup_pattern="${target_path}.backup.*"
        for backup in ${backup_pattern}; do
            [[ -e "$backup" ]] && backup_count=$((backup_count + 1))
        done

        if [[ $backup_count -gt 0 ]]; then
            echo -e "    ${DIM}Existing backups: $backup_count${NC}"
        fi
    done
    echo

    # Show actions that will be taken
    if [[ $DRY_RUN -eq 1 ]]; then
        echo -e "${BOLD}Actions (DRY RUN):${NC}"
    else
        echo -e "${BOLD}Actions:${NC}"
    fi

    if [[ $NO_BACKUP -eq 0 ]]; then
        echo -e "  ${BLUE}✓${NC} Create backups before removal"
    else
        echo -e "  ${DIM}○ Skip backups (--no-backup)${NC}"
    fi

    echo -e "  ${RED}✗${NC} Remove target directories"

    if [[ $clean_backups == true ]]; then
        echo -e "  ${YELLOW}🗑${NC} Clean existing backup files"
    fi

    echo -e "  ${CYAN}📝${NC} Update registry"
    echo

    # Confirmation
    if [[ $FORCE -eq 0 ]] && [[ $DRY_RUN -eq 0 ]]; then
        if ! confirm "Remove ${#valid_modules[@]} module(s)?"; then
            log_info "Removal cancelled"
            exit 0
        fi
    fi

    # Ensure yq for registry updates
    ensure_yq >/dev/null 2>&1

    # Perform removal
    local successful=0
    local failed=0

    if [[ $DRY_RUN -eq 1 ]]; then
        log_info "DRY RUN: Would remove ${#valid_modules[@]} modules"
    else
        log_info "Removing ${#valid_modules[@]} modules..."
    fi

    echo

    for module in "${valid_modules[@]}"; do
        if remove_single_module "$module"; then
            successful=$((successful + 1))
        else
            failed=$((failed + 1))
        fi

        # Clean backups if requested
        if [[ $clean_backups == true ]]; then
            clean_module_backups "$module"
        fi
    done

    # Update registry
    if [[ $successful -gt 0 ]] && [[ $DRY_RUN -eq 0 ]]; then
        update_removal_registry "${valid_modules[@]}"
    fi

    # Summary
    echo
    echo -e "${BOLD}Removal Summary:${NC}"
    if [[ $DRY_RUN -eq 1 ]]; then
        echo -e "  ${BLUE}Would remove:${NC} ${#valid_modules[@]} modules"
    else
        echo -e "  ${GREEN}Successful:${NC} $successful"
        if [[ $failed -gt 0 ]]; then
            echo -e "  ${RED}Failed:${NC} $failed"
        fi
        echo -e "  ${BOLD}Total:${NC} ${#valid_modules[@]}"

        if [[ $successful -gt 0 ]]; then
            if [[ $NO_BACKUP -eq 0 ]]; then
                echo -e "  ${BLUE}Backups:${NC} Created before removal"
            fi
            echo -e "  ${CYAN}Registry:${NC} Updated"
        fi
    fi

    if [[ $DRY_RUN -eq 0 && $successful -gt 0 ]]; then
        echo
        log_success "Removal completed successfully!"
        if [[ $NO_BACKUP -eq 0 ]]; then
            log_info "Backups were created - you can restore modules if needed"
        fi
    fi

    # Return appropriate exit code
    if [[ $failed -gt 0 ]]; then
        return 1
    fi
    return 0
}
