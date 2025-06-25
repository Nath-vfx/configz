#!/usr/bin/env bash

# Configz - Migrate Command
# Migrate modules from old locations to new structure

# Source common library
# shellcheck source=../lib/common.sh
source "$CLI_DIR/lib/common.sh"

# =============================================================================
# MIGRATE COMMAND FUNCTIONS
# =============================================================================

show_migrate_help() {
    cat << EOF
$PROGRAM_NAME migrate - Migrate modules to new directory structure

USAGE:
    $PROGRAM_NAME migrate [OPTIONS] [SOURCE_DIR]

OPTIONS:
    -h, --help          Show this help message
    -f, --force         Force migration, overwrite existing modules
    -n, --dry-run       Show what would be migrated without executing
    --from DIR          Specify source directory (default: ./config)
    --backup            Create backup before migration
    --clean             Remove source directory after successful migration

ARGUMENTS:
    SOURCE_DIR          Directory containing modules to migrate

EXAMPLES:
    $PROGRAM_NAME migrate                       # Migrate from ./config
    $PROGRAM_NAME migrate --from ~/old-configs  # Migrate from custom directory
    $PROGRAM_NAME migrate --dry-run             # Preview migration
    $PROGRAM_NAME migrate --force --backup      # Force migration with backup

DESCRIPTION:
    Migrates configuration modules from old directory structure to the new
    ~/.config/configz/modules/ location. This command helps transition from
    development setups to the standardized user configuration structure.

    The migration process:
    1. Creates new directory structure in ~/.config/configz/
    2. Copies modules preserving their structure
    3. Updates registry and metadata
    4. Optionally creates backups and cleans old location

EOF
}

# Validate module directory structure and content
validate_module() {
    local module_dir="$1"
    local module_name
    module_name=$(basename "$module_dir")
    
    # Check for dangerous patterns in scripts
    local dangerous_patterns=(
        'rm\s+-[rf]' 'chmod\s+[0-7]{3,4}\s+/' 'chown\s+[^\s]+\s+/' 
        'wget\s+' 'curl\s+-[^\s]*[OL]' '\|\s*sh\s*$' '>\s*/dev/' '>>\s*/dev/'
    )
    
    # Check for suspicious file types
    local suspicious_files
    suspicious_files=$(find "$module_dir" -type f \( \
        -name '*.sh' -o -name '*.bash' -o -name '*.zsh' -o -name '*.py' -o -name '*.rb' \
        -o -perm -111 -a -type f -not -name '*.so' -not -name '*.dylib' \
    \) 2>/dev/null)
    
    for file in $suspicious_files; do
        for pattern in "${dangerous_patterns[@]}"; do
            if grep -qE "$pattern" "$file" 2>/dev/null; then
                log_warning "Potentially dangerous pattern in $module_name: $(basename "$file")"
                log_debug "Pattern: $pattern in $file"
                return 1
            fi
        done
    done
    
    return 0
}

# Check if source directory has modules and validate them
check_source_directory() {
    local source_dir="$1"
    local max_module_size_mb=50  # 50MB max per module
    local max_total_size_mb=500  # 500MB max total
    local total_size_kb=0
    local module_count=0

    if [[ ! -d "$source_dir" ]]; then
        log_error "Source directory not found: $source_dir"
        return 1
    fi

    # Check if we can read the directory
    if [[ ! -r "$source_dir" ]]; then
        log_error "Cannot read source directory: $source_dir"
        return 1
    fi

    # Check for modules
    while IFS= read -r -d '' module_dir; do
        if [[ ! -d "$module_dir" ]]; then
            continue
        fi

        # Validate module name (basic check)
        local module_name
        module_name=$(basename "$module_dir")
        if [[ ! "$module_name" =~ ^[a-zA-Z0-9_.-]+$ ]]; then
            log_warning "Skipping module with invalid name: $module_name"
            continue
        fi

        # Check module size
        local module_size_kb
        module_size_kb=$(du -sk "$module_dir" 2>/dev/null | cut -f1)
        
        if (( module_size_kb > max_module_size_mb * 1024 )); then
            log_warning "Module $module_name is too large ($((module_size_kb/1024))MB > ${max_module_size_mb}MB), skipping"
            continue
        fi

        # Validate module content
        if ! validate_module "$module_dir"; then
            log_warning "Module $module_name contains potentially dangerous content, skipping"
            continue
        fi

        total_size_kb=$((total_size_kb + module_size_kb))
        module_count=$((module_count + 1))
    done < <(find "$source_dir" -maxdepth 1 -type d -not -name "$(basename "$source_dir")" -print0)

    if [[ $module_count -eq 0 ]]; then
        log_warning "No valid modules found in source directory: $source_dir"
        return 1
    fi

    # Check total size
    if (( total_size_kb > max_total_size_mb * 1024 )); then
        log_error "Total size of modules ($((total_size_kb/1024))MB) exceeds maximum allowed (${max_total_size_mb}MB)"
        return 1
    fi

    # Check available disk space (need 2x total size for safety)
    local available_kb
    available_kb=$(df -k "$(dirname "$CONFIG_SOURCE_DIR")" | tail -1 | awk '{print $4}')
    
    if (( total_size_kb * 2 > available_kb )); then
        log_error "Not enough disk space. Required: $((total_size_kb/1024))MB, Available: $((available_kb/1024))MB"
        return 1
    fi

    log_info "Found $module_count valid modules (total size: $((total_size_kb/1024))MB)"
    return 0
}

# Preview migration
preview_migration() {
    local source_dir="$1"

    echo -e "${BOLD}Migration Preview:${NC}"
    echo -e "${DIM}From: $source_dir${NC}"
    echo -e "${DIM}To:   $CONFIG_SOURCE_DIR${NC}"
    echo

    echo -e "${BOLD}Modules to migrate:${NC}"

    while IFS= read -r -d '' module_dir; do
        if [[ ! -d "$module_dir" ]]; then
            continue
        fi

        local module_name
        module_name=$(basename "$module_dir")
        local target_path="$CONFIG_SOURCE_DIR/$module_name"
        local file_count
        file_count=$(find "$module_dir" -type f | wc -l)

        echo -e "  ${CYAN}$module_name${NC}"
        echo -e "    Source: $module_dir"
        echo -e "    Target: $target_path"
        echo -e "    Files:  $file_count"

        if [[ -d "$target_path" ]]; then
            echo -e "    ${YELLOW}Status: Target exists (would overwrite with --force)${NC}"
        else
            echo -e "    ${GREEN}Status: Ready to migrate${NC}"
        fi
        echo
    done < <(find "$source_dir" -maxdepth 1 -type d -not -name "$(basename "$source_dir")" -print0)

    # Show structure that will be created
    echo -e "${BOLD}Directory structure that will be created:${NC}"
    echo -e "  $(dirname "$CONFIG_SOURCE_DIR")/"
    echo -e "  ├── modules/           # Migrated modules"
    echo -e "  ├── backups/           # Backup storage"
    echo -e "  ├── cache/             # Cache data"
    echo -e "  ├── config.toml        # Global configuration"
    echo -e "  └── registry.json      # Module registry"
}

# Perform actual migration
perform_migration() {
    local source_dir="$1"
    local force_migration="$2"
    local create_backup="$3"

    log_info "Starting migration from $source_dir"

    # Initialize structure
    init_configz_structure

    # Create backup of existing modules if requested
    if [[ "$create_backup" == "true" && -d "$CONFIG_SOURCE_DIR" ]]; then
        local backup_dir
        backup_dir="$(dirname "$CONFIG_SOURCE_DIR")/backups/migration_$(date +%Y%m%d_%H%M%S)"
        mkdir -p "$backup_dir"

        if cp -r "$CONFIG_SOURCE_DIR" "$backup_dir/" 2>/dev/null; then
            log_info "Created backup: $backup_dir"
        fi
    fi

    local migrated_count=0
    local skipped_count=0
    local error_count=0

    while IFS= read -r -d '' module_dir; do
        if [[ ! -d "$module_dir" ]]; then
            continue
        fi

        local module_name
        module_name=$(basename "$module_dir")
        local target_path="$CONFIG_SOURCE_DIR/$module_name"

        log_info "Processing module: $module_name"

        # Check if target exists
        if [[ -d "$target_path" ]]; then
            if [[ "$force_migration" != "true" ]]; then
                log_warning "Module $module_name already exists at target, skipping"
                ((skipped_count++))
                continue
            else
                log_info "Overwriting existing module: $module_name"
                rm -rf "$target_path"
            fi
        fi

        # Copy module
        if [[ $DRY_RUN -eq 1 ]]; then
            log_info "Would copy: $module_dir -> $target_path"
        else
            if cp -r "$module_dir" "$target_path"; then
                log_success "Migrated: $module_name"
                ((migrated_count++))
            else
                log_error "Failed to migrate: $module_name"
                ((error_count++))
            fi
        fi

    done < <(find "$source_dir" -maxdepth 1 -type d -not -name "$(basename "$source_dir")" -print0)

    # Update registry
    if [[ $DRY_RUN -eq 0 && $migrated_count -gt 0 ]]; then
        update_migration_registry "$migrated_count"
    fi

    # Summary
    echo
    echo -e "${BOLD}Migration Summary:${NC}"
    echo -e "  ${GREEN}Migrated:${NC} $migrated_count modules"
    if [[ $skipped_count -gt 0 ]]; then
        echo -e "  ${YELLOW}Skipped:${NC}  $skipped_count modules"
    fi
    if [[ $error_count -gt 0 ]]; then
        echo -e "  ${RED}Errors:${NC}   $error_count modules"
    fi

    if [[ $migrated_count -gt 0 ]]; then
        echo
        log_success "Migration completed successfully!"
        log_info "Modules are now available at: $CONFIG_SOURCE_DIR"
        log_info "You can now use: $PROGRAM_NAME list"
    fi
}

# Update registry after migration
update_migration_registry() {
    local migrated_count="$1"
    local registry_file
    registry_file="$(dirname "$CONFIG_SOURCE_DIR")/registry.json"

    if [[ -f "$registry_file" ]] && command -v jq >/dev/null 2>&1; then
        local temp_file
        temp_file=$(mktemp)

        jq --arg date "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" \
           --arg count "$migrated_count" \
           '.migration_completed = true | .last_migration = $date | .migrated_modules = ($count | tonumber)' \
           "$registry_file" > "$temp_file" && mv "$temp_file" "$registry_file"

        log_debug "Updated registry with migration info"
    fi
}

# Clean source directory after migration
clean_source_directory() {
    local source_dir="$1"

    if [[ ! -d "$source_dir" ]]; then
        return 0
    fi

    log_info "Cleaning source directory: $source_dir"

    if confirm "Remove source directory after successful migration?"; then
        if [[ $DRY_RUN -eq 1 ]]; then
            log_info "Would remove: $source_dir"
        else
            if rm -rf "$source_dir"; then
                log_success "Removed source directory: $source_dir"
            else
                log_error "Failed to remove source directory: $source_dir"
            fi
        fi
    else
        log_info "Source directory preserved: $source_dir"
    fi
}

# =============================================================================
# MAIN COMMAND FUNCTION
# =============================================================================

migrate_main() {
    local source_dir=""
    local force_migration=false
    local create_backup=false
    local clean_after=false

    # Parse command-specific options
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_migrate_help
                exit 0
                ;;
            -f|--force)
                force_migration=true
                shift
                ;;
            --from)
                if [[ -n "${2:-}" ]]; then
                    source_dir="$2"
                    shift 2
                else
                    log_error "Option --from requires a directory path"
                    exit 1
                fi
                ;;
            --backup)
                create_backup=true
                shift
                ;;
            --clean)
                clean_after=true
                shift
                ;;
            -n|--dry-run)
                DRY_RUN=1
                shift
                ;;
            -*)
                log_error "Unknown option: $1"
                log_info "Use '$PROGRAM_NAME migrate --help' for available options"
                exit 1
                ;;
            *)
                if [[ -z "$source_dir" ]]; then
                    source_dir="$1"
                else
                    log_error "Multiple source directories specified"
                    exit 1
                fi
                shift
                ;;
        esac
    done

    # Require explicit source directory
    if [[ -z "$source_dir" ]]; then
        log_error "No source directory specified"
        log_info "Please specify a source directory with --from <directory>"
        log_info "Example: $PROGRAM_NAME migrate --from ~/my-configs"
        exit 1
    fi

    # Convert to absolute path
    source_dir=$(cd "$source_dir" 2>/dev/null && pwd || echo "$source_dir")

    # Validate source directory
    if ! check_source_directory "$source_dir"; then
        exit 1
    fi

    # Check if source and target are the same
    if [[ "$source_dir" == "$CONFIG_SOURCE_DIR" ]]; then
        log_info "Source and target directories are the same, no migration needed"
        exit 0
    fi

    # Ensure yq for advanced features
    ensure_yq >/dev/null 2>&1

    # Show preview if dry run
    if [[ $DRY_RUN -eq 1 ]]; then
        preview_migration "$source_dir"
        exit 0
    fi

    # Show preview
    preview_migration "$source_dir"
    echo

    # Show detailed warning and get confirmation
    if [[ $FORCE -eq 0 ]]; then
        echo -e "${YELLOW}╔════════════════════════════════════════════════════════════╗${NC}"
        echo -e "${YELLOW}║ ${BOLD}WARNING: Migration Safety Check${NC}${YELLOW}                          ║${NC}"
        echo -e "${YELLOW}╠════════════════════════════════════════════════════════════╣${NC}"
        echo -e "${YELLOW}║ You are about to migrate modules to:                       ║${NC}"
        echo -e "${YELLOW}║   ${CONFIG_SOURCE_DIR}${NC}"
        echo -e "${YELLOW}║                                                              ║"
        echo -e "${YELLOW}║ This operation will:                                        ║"
        echo -e "${YELLOW}║ • Copy module directories to the new location              ║"
        [[ "$force_migration" == "true" ]] && \
        echo -e "${YELLOW}║ • ${RED}Overwrite${YELLOW} any existing modules (--force)${YELLOW}              ║"
        [[ "$create_backup" == "true" ]] && \
        echo -e "${YELLOW}║ • Create backups of existing modules before overwriting     ║"
        [[ "$clean_after" == "true" ]] && \
        echo -e "${YELLOW}║ • ${RED}Delete${YELLOW} source modules after migration (--clean)${YELLOW}         ║"
        echo -e "${YELLOW}╚════════════════════════════════════════════════════════════╝${NC}"
        echo
        
        echo -n "Type 'MIGRATE' to confirm or anything else to cancel: "
        read -r user_confirmation
        
        if [[ "$user_confirmation" != "MIGRATE" ]]; then
            log_info "Migration cancelled by user"
            exit 0
        fi
        echo
    fi

    # Perform migration
    perform_migration "$source_dir" "$force_migration" "$create_backup"

    # Clean source directory if requested and migration was successful
    if [[ "$clean_after" == "true" && $? -eq 0 ]]; then
        clean_source_directory "$source_dir"
    fi
}
