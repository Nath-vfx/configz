#!/usr/bin/env bash

# Configz - Common Library Functions
# Shared utilities for all CLI commands

# =============================================================================
# MODULE DISCOVERY AND MANAGEMENT
# =============================================================================

# Get all available modules
get_available_modules() {
    local modules=()

    if [[ ! -d "$CONFIG_SOURCE_DIR" ]]; then
        return 0
    fi

    while IFS= read -r -d '' dir; do
        local module_name
        module_name=$(basename "$dir")
        modules+=("$module_name")
    done < <(find "$CONFIG_SOURCE_DIR" -mindepth 1 -maxdepth 1 -type d -print0)
    printf '%s\n' "${modules[@]}" | sort
}

# Check if module exists
module_exists() {
    local module="$1"
    [[ -d "$CONFIG_SOURCE_DIR/$module" ]]
}

# Get module path
get_module_path() {
    local module="$1"
    echo "$CONFIG_SOURCE_DIR/$module"
}

# Get module target path
get_module_target_path() {
    local module="$1"
    local config_file="$CONFIG_SOURCE_DIR/$module/configz.toml"

    set +e
    if [[ -f "$config_file" ]] && command -v yq >/dev/null 2>&1; then
        local custom_target
        custom_target=$(yq eval '.paths.target // ""' "$config_file" 2>/dev/null || echo "")
        if [[ -n "$custom_target" && "$custom_target" != "null" && "$custom_target" != '""' ]]; then
            set -e
            echo "$TARGET_BASE_DIR/$custom_target"
            return 0
        fi
    fi
    set -e

    # Default target path
    echo "$TARGET_BASE_DIR/$module"
    return 0
}

# Check if module is installed
is_module_installed() {
    local module="$1"
    local target_path
    set +e
    target_path=$(get_module_target_path "$module")
    local result=0
    # Check if target exists (directory or symlink)
    [[ -d "$target_path" || -L "$target_path" ]] || result=1
    set -e
    return $result
}

# =============================================================================
# MODULE METADATA
# =============================================================================

# Safe wrapper for functions that might fail
safe_call() {
    set +e
    local result
    result=$("$@" 2>/dev/null)
    local exit_code=$?
    set -e

    if [[ $exit_code -eq 0 && -n "$result" && "$result" != "null" ]]; then
        echo "$result"
        return 0
    else
        return 1
    fi
}

# Read module metadata from configz.toml
read_module_metadata() {
    local module="$1"
    local key="$2"
    local default="$3"
    local config_file="$CONFIG_SOURCE_DIR/$module/configz.toml"

    set +e
    if [[ -f "$config_file" ]] && command -v yq >/dev/null 2>&1; then
        local value
        value=$(yq eval ".$key // \"\"" "$config_file" 2>/dev/null || echo "")
        if [[ -n "$value" && "$value" != "null" && "$value" != '""' ]]; then
            set -e
            echo "$value"
            return 0
        fi
    fi
    set -e

    echo "$default"
    return 0
}

# Get module name (from config or directory name)
get_module_name() {
    local module="$1"
    local name
    name=$(read_module_metadata "$module" "module.name" "")
    if [[ -n "$name" ]]; then
        echo "$name"
    else
        # Capitalize first letter of directory name
        echo "${module^}"
    fi
}

# Get module description
get_module_description() {
    local module="$1"
    read_module_metadata "$module" "module.description" "Configuration for $(get_module_name "$module")"
}

# Get module icon
get_module_icon() {
    local module="$1"
    read_module_metadata "$module" "module.icon" "📦"
}

# Get module version
get_module_version() {
    local module="$1"
    read_module_metadata "$module" "module.version" "1.0.0"
}

# Get module author
get_module_author() {
    local module="$1"
    read_module_metadata "$module" "module.author" "Unknown"
}

# =============================================================================
# FILE OPERATIONS
# =============================================================================

# Create backup of existing configuration
create_backup() {
    local target_path="$1"
    local timestamp
    timestamp=$(date +"%Y%m%d_%H%M%S")
    local backup_path="${target_path}.backup.${timestamp}"

    if [[ -e "$target_path" ]]; then
        if [[ $DRY_RUN -eq 1 ]]; then
            log_info "Would backup: $target_path -> $backup_path"
        else
            cp -r "$target_path" "$backup_path"
            log_info "Backup created: $backup_path"
        fi
        echo "$backup_path"
    fi
}

# Install files from module to target
install_module_files() {
    local module="$1"
    local source_path="$CONFIG_SOURCE_DIR/$module"
    local target_path
    target_path=$(get_module_target_path "$module")

    # Create backup if target exists and backup is enabled
    if [[ $NO_BACKUP -eq 0 ]] && [[ -e "$target_path" ]]; then
        create_backup "$target_path"
    fi

    # Remove existing target if it exists
    if [[ -e "$target_path" || -L "$target_path" ]]; then
        if [[ $DRY_RUN -eq 1 ]]; then
            log_info "Would remove existing: $target_path"
        else
            rm -rf "$target_path"
        fi
    fi

    if [[ $NO_SYMLINK -eq 1 ]]; then
        # Legacy mode: copy files to target directory
        if [[ $DRY_RUN -eq 1 ]]; then
            log_info "Would create directory: $target_path"
        else
            mkdir -p "$target_path"
        fi

        # Copy files (excluding configz.toml)
        local files_copied=0
        while IFS= read -r -d '' file; do
            local relative_path="${file#$source_path/}"

            # Skip configz.toml
            if [[ "$relative_path" == "configz.toml" ]]; then
                continue
            fi

            local target_file="$target_path/$relative_path"
            local target_dir
            target_dir=$(dirname "$target_file")

            if [[ $DRY_RUN -eq 1 ]]; then
                log_info "Would copy: $relative_path"
            else
                mkdir -p "$target_dir"
                cp -r "$file" "$target_file"
                log_debug "Copied: $relative_path"
            fi

            ((files_copied++))
        done < <(find "$source_path" -type f -print0)

        if [[ $files_copied -eq 0 ]]; then
            log_warning "No files found to install in module '$module'"
            return 1
        fi

        log_success "Installed module '$module' ($files_copied files copied)"
    else
        # New default mode: create symlink to module directory
        if [[ $DRY_RUN -eq 1 ]]; then
            log_info "Would create symlink: $target_path -> $source_path"
        else
            # Ensure parent directory exists
            mkdir -p "$(dirname "$target_path")"
            
            # Create symlink
            ln -sf "$source_path" "$target_path"
            log_debug "Created symlink: $target_path -> $source_path"
        fi

        log_success "Installed module '$module' (symlinked)"
    fi

    return 0
}

# Remove module files
remove_module_files() {
    local module="$1"
    local target_path
    target_path=$(get_module_target_path "$module")

    if [[ ! -e "$target_path" && ! -L "$target_path" ]]; then
        log_warning "Module '$module' is not installed"
        return 1
    fi

    # Check if it's a symlink or a copied directory
    if [[ -L "$target_path" ]]; then
        log_info "Removing symlinked module: $module"
        
        # Create backup before removal (backup the symlink itself)
        if [[ $NO_BACKUP -eq 0 ]]; then
            local timestamp
            timestamp=$(date +"%Y%m%d_%H%M%S")
            local backup_path="${target_path}.symlink_backup.${timestamp}"
            
            if [[ $DRY_RUN -eq 1 ]]; then
                log_info "Would backup symlink: $target_path -> $backup_path"
            else
                cp -P "$target_path" "$backup_path"
                log_info "Backup created: $backup_path"
            fi
        fi

        # Remove the symlink
        if [[ $DRY_RUN -eq 1 ]]; then
            log_info "Would remove symlink: $target_path"
        else
            rm "$target_path"
            log_success "Removed symlink: $target_path"
        fi
    else
        log_info "Removing copied module: $module"
        
        # Create backup before removal
        if [[ $NO_BACKUP -eq 0 ]]; then
            create_backup "$target_path"
        fi

        if [[ $DRY_RUN -eq 1 ]]; then
            log_info "Would remove directory: $target_path"
        else
            rm -rf "$target_path"
            log_success "Removed directory: $target_path"
        fi
    fi

    return 0
}

# =============================================================================
# VALIDATION AND DEPENDENCIES
# =============================================================================

# Check system dependencies
check_system_dependencies() {
    local module="$1"
    local deps
    set +e
    deps=$(read_module_metadata "$module" "dependencies.system" "")
    set -e

    if [[ -z "$deps" || "$deps" == "null" ]]; then
        return 0
    fi

    # Parse dependencies (space or comma separated)
    local missing_deps=()
    local dep_list
    dep_list=$(echo "$deps" | tr ',' ' ' | tr -s ' ')

    set +e
    for dep in $dep_list; do
        if ! command -v "$dep" >/dev/null 2>&1; then
            missing_deps+=("$dep")
        fi
    done
    set -e

    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        log_error "Module '$module' requires missing system dependencies: ${missing_deps[*]}"
        return 1
    fi

    return 0
}

# Check module dependencies
check_module_dependencies() {
    local module="$1"
    local deps
    set +e
    deps=$(read_module_metadata "$module" "dependencies.modules" "")
    set -e

    if [[ -z "$deps" || "$deps" == "null" ]]; then
        return 0
    fi

    local missing_deps=()
    local dep_list
    dep_list=$(echo "$deps" | tr ',' ' ' | tr -s ' ')

    set +e
    for dep in $dep_list; do
        if ! is_module_installed "$dep"; then
            missing_deps+=("$dep")
        fi
    done
    set -e

    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        log_error "Module '$module' requires missing module dependencies: ${missing_deps[*]}"
        log_info "Install them first: $PROGRAM_NAME install ${missing_deps[*]}"
        return 1
    fi

    return 0
}

# =============================================================================
# FORMATTING AND DISPLAY
# =============================================================================

# Get module installation type
get_module_installation_type() {
    local module="$1"
    local target_path
    target_path=$(get_module_target_path "$module")

    if [[ ! -e "$target_path" && ! -L "$target_path" ]]; then
        echo "not_installed"
        return 1
    fi

    if [[ -L "$target_path" ]]; then
        echo "symlink"
    else
        echo "copy"
    fi
}

# Format module status for display
format_module_status() {
    local module="$1"
    local name icon status_icon status_text installation_type

    name=$(get_module_name "$module")
    icon=$(get_module_icon "$module")

    if is_module_installed "$module"; then
        installation_type=$(get_module_installation_type "$module")
        if [[ "$installation_type" == "symlink" ]]; then
            status_icon="${GREEN}🔗${NC}"
            status_text="${GREEN}installed (symlink)${NC}"
        else
            status_icon="${GREEN}📁${NC}"
            status_text="${GREEN}installed (copy)${NC}"
        fi
    else
        status_icon="${DIM}○${NC}"
        status_text="${DIM}not installed${NC}"
    fi

    printf "%s %s %-20s %s\n" "$status_icon" "$icon" "$name" "$status_text"
}

# Display module details
show_module_info() {
    local module="$1"

    if ! module_exists "$module"; then
        log_error "Module '$module' not found"
        return 1
    fi

    local name description icon version author target_path
    name=$(get_module_name "$module")
    description=$(get_module_description "$module")
    icon=$(get_module_icon "$module")
    version=$(get_module_version "$module")
    author=$(get_module_author "$module")
    target_path=$(get_module_target_path "$module")

    echo -e "\n${BOLD}${icon} ${name}${NC}"
    echo -e "${DIM}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BOLD}Description:${NC} $description"
    echo -e "${BOLD}Version:${NC}     $version"
    echo -e "${BOLD}Author:${NC}      $author"
    echo -e "${BOLD}Module Path:${NC} $CONFIG_SOURCE_DIR/$module"
    echo -e "${BOLD}Target Path:${NC} $target_path"

    if is_module_installed "$module"; then
        echo -e "${BOLD}Status:${NC}      ${GREEN}✓ Installed${NC}"
    else
        echo -e "${BOLD}Status:${NC}      ${DIM}○ Not installed${NC}"
    fi

    # Show files that would be installed
    echo -e "\n${BOLD}Files:${NC}"
    local files=()
    while IFS= read -r -d '' file; do
        local relative_path="${file#$CONFIG_SOURCE_DIR/$module/}"
        if [[ "$relative_path" != "configz.toml" ]]; then
            files+=("  $relative_path")
        fi
    done < <(find "$CONFIG_SOURCE_DIR/$module" -type f -print0)

    if [[ ${#files[@]} -eq 0 ]]; then
        echo -e "  ${DIM}(no files found)${NC}"
    else
        printf '%s\n' "${files[@]}"
    fi

    # Show dependencies
    local sys_deps mod_deps
    sys_deps=$(read_module_metadata "$module" "dependencies.system" "")
    mod_deps=$(read_module_metadata "$module" "dependencies.modules" "")

    if [[ -n "$sys_deps" ]] || [[ -n "$mod_deps" ]]; then
        echo -e "\n${BOLD}Dependencies:${NC}"
        if [[ -n "$sys_deps" ]]; then
            echo -e "  ${BOLD}System:${NC} $sys_deps"
        fi
        if [[ -n "$mod_deps" ]]; then
            echo -e "  ${BOLD}Modules:${NC} $mod_deps"
        fi
    fi

    echo
}

# =============================================================================
# CONFIRMATION AND INTERACTION
# =============================================================================

# Ask for confirmation
confirm() {
    local message="$1"
    local default="${2:-n}"

    if [[ $FORCE -eq 1 ]]; then
        return 0
    fi

    local prompt
    if [[ "$default" == "y" ]]; then
        prompt="[Y/n]"
    else
        prompt="[y/N]"
    fi

    while true; do
        read -p "$message $prompt " -r response
        response=${response:-$default}

        case "${response,,}" in
            y|yes) return 0 ;;
            n|no) return 1 ;;
            *) echo "Please answer yes or no." ;;
        esac
    done
}

# =============================================================================
# UTILITY FUNCTIONS
# =============================================================================

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

# =============================================================================
# MIGRATION AND INITIALIZATION
# =============================================================================

# Migrate modules from old location to new structure
migrate_modules() {
    local old_config_dir="$1"
    local force_migration="${2:-false}"

    if [[ ! -d "$old_config_dir" ]]; then
        return 0
    fi

    log_info "Found modules in old location: $old_config_dir"

    # Check if new location has modules
    local existing_modules
    existing_modules=$(find "$CONFIG_SOURCE_DIR" -maxdepth 1 -type d -not -name "$(basename "$CONFIG_SOURCE_DIR")" 2>/dev/null | wc -l)

    if [[ $existing_modules -gt 0 && "$force_migration" != "true" ]]; then
        log_warning "Modules already exist in new location. Use --force-migration to overwrite."
        return 0
    fi

    # Create new structure
    mkdir -p "$CONFIG_SOURCE_DIR"
    mkdir -p "$(dirname "$CONFIG_SOURCE_DIR")/backups"
    mkdir -p "$(dirname "$CONFIG_SOURCE_DIR")/cache"

    # Copy modules
    local migrated_count=0
    while IFS= read -r -d '' module_dir; do
        local module_name
        module_name=$(basename "$module_dir")

        log_info "Migrating module: $module_name"

        if [[ -d "$CONFIG_SOURCE_DIR/$module_name" ]]; then
            log_warning "Module $module_name already exists, skipping"
        else
            cp -r "$module_dir" "$CONFIG_SOURCE_DIR/"
            ((migrated_count++))
            log_success "Migrated: $module_name"
        fi
    done < <(find "$old_config_dir" -maxdepth 1 -type d -not -name "$(basename "$old_config_dir")" -print0)

    if [[ $migrated_count -gt 0 ]]; then
        log_success "Migrated $migrated_count modules to new location"
        log_info "Old modules remain in: $old_config_dir"
        log_info "New location: $CONFIG_SOURCE_DIR"
    fi
}

# Initialize configz directory structure
init_configz_structure() {
    local configz_dir
    configz_dir=$(dirname "$CONFIG_SOURCE_DIR")

    # Create main directories
    mkdir -p "$CONFIG_SOURCE_DIR"
    mkdir -p "$configz_dir/backups"
    mkdir -p "$configz_dir/cache"

    # Create global config if it doesn't exist
    local global_config="$configz_dir/config.toml"
    if [[ ! -f "$global_config" ]]; then
        cat > "$global_config" << 'EOF'
# Configz Global Configuration
# This file controls the behavior of the Configz CLI

[settings]
# Default behavior settings
auto_backup = true
backup_count = 5
verbose = false
use_colors = true

[paths]
# Path settings (relative to ~/.config/configz/)
modules_dir = "modules"
backups_dir = "backups"
cache_dir = "cache"

[sources]
# External module sources (future feature)
# github_repos = []
# custom_urls = []

[hooks]
# Command hooks (future feature)
# pre_install = []
# post_install = []
EOF
        log_info "Created global config: $global_config"
    fi

    # Create registry file
    local registry_file="$configz_dir/registry.json"
    if [[ ! -f "$registry_file" ]]; then
        cat > "$registry_file" << 'EOF'
{
  "version": "0.2.0-alpha",
  "installed_modules": {},
  "last_updated": "",
  "migration_completed": false
}
EOF
        log_info "Created registry: $registry_file"
    fi
}

# Check for migration needs
check_migration() {
    local script_dir="$1"
    local old_config_dir="$script_dir/config"

    # If running from development directory and modules exist there
    if [[ -d "$old_config_dir" && "$CONFIG_SOURCE_DIR" != "$old_config_dir" ]]; then
        local module_count
        module_count=$(find "$old_config_dir" -maxdepth 1 -type d -not -name config 2>/dev/null | wc -l)

        if [[ $module_count -gt 0 ]]; then
            log_info "Found $module_count modules in development directory"
            if confirm "Migrate modules from $old_config_dir to $CONFIG_SOURCE_DIR?" "y"; then
                migrate_modules "$old_config_dir"
            fi
        fi
    fi
}

# Ensure yq is available
ensure_yq() {
    if ! command -v yq >/dev/null 2>&1; then
        log_warning "yq not found - TOML parsing will be limited"
        if command -v brew >/dev/null 2>&1; then
            if confirm "Install yq via Homebrew for full TOML support?" 2>/dev/null; then
                brew install yq || return 1
                return 0
            fi
        fi
        log_info "Some features may be limited without yq"
        return 1
    fi
    return 0
}
