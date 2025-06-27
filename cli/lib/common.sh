#!/usr/bin/env bash

# Configz - Common Library Functions
# Shared utilities for all CLI commands

# =============================================================================
# MODULE DISCOVERY AND MANAGEMENT
# =============================================================================

# Get all available modules
get_available_modules() {
    local include_hidden="${1:-false}"
    local modules=()

    if [[ ! -d "$CONFIG_SOURCE_DIR" ]]; then
        return 0
    fi

    while IFS= read -r -d '' dir; do
        local module_name
        module_name=$(basename "$dir")
        
        # Skip hidden directories unless explicitly requested
        if [[ "$module_name" =~ ^\..*$ ]] && [[ "$include_hidden" != "true" ]]; then
            continue
        fi
        
        # Skip if directory is empty (no files or subdirectories)
        if [[ -z "$(find "$dir" -mindepth 1 -maxdepth 1 2>/dev/null)" ]]; then
            continue
        fi
        
        # Skip if directory contains only hidden files/directories and include_hidden is false
        if [[ "$include_hidden" != "true" ]]; then
            local has_visible_content=false
            while IFS= read -r -d '' item; do
                local item_name
                item_name=$(basename "$item")
                if [[ ! "$item_name" =~ ^\..*$ ]]; then
                    has_visible_content=true
                    break
                fi
            done < <(find "$dir" -mindepth 1 -maxdepth 1 -print0 2>/dev/null)
            
            if [[ "$has_visible_content" != "true" ]]; then
                continue
            fi
        fi
        
        modules+=("$module_name")
    done < <(find "$CONFIG_SOURCE_DIR" -mindepth 1 -maxdepth 1 -type d -print0 2>/dev/null)
    
    printf '%s\n' "${modules[@]}" | sort
}

# Check if module exists (common implementation)
module_exists_common() {
    local module="$1"
    
    # Debug: Print function arguments and environment
    log_debug "[module_exists_common] Function called with module: $module"
    log_debug "[module_exists_common] CONFIG_SOURCE_DIR: $CONFIG_SOURCE_DIR"
    log_debug "[module_exists_common] Full path being checked: $CONFIG_SOURCE_DIR/$module"
    
    # Check if CONFIG_SOURCE_DIR is set
    if [[ -z "$CONFIG_SOURCE_DIR" ]]; then
        log_debug "[module_exists_common] ERROR: CONFIG_SOURCE_DIR is not set"
        return 1
    fi
    
    # Check if CONFIG_SOURCE_DIR exists
    if [[ ! -d "$CONFIG_SOURCE_DIR" ]]; then
        log_debug "[module_exists_common] ERROR: CONFIG_SOURCE_DIR does not exist: $CONFIG_SOURCE_DIR"
        return 1
    fi
    
    # Check if module directory exists
    if [[ -d "$CONFIG_SOURCE_DIR/$module" ]]; then
        log_debug "[module_exists_common] Module directory exists: $CONFIG_SOURCE_DIR/$module"
        
        # Check if the directory is readable
        if [[ ! -r "$CONFIG_SOURCE_DIR/$module" ]]; then
            log_debug "[module_exists_common] WARNING: Module directory exists but is not readable: $CONFIG_SOURCE_DIR/$module"
            return 1
        fi
        
        # List contents of the module directory for debugging
        log_debug "[module_exists_common] Module directory contents: $(ls -la "$CONFIG_SOURCE_DIR/$module" 2>&1 || echo "Cannot list module directory")"
        
        log_debug "[module_exists_common] Module '$module' found and is accessible"
        return 0
    else
        log_debug "[module_exists_common] Module directory does not exist: $CONFIG_SOURCE_DIR/$module"
        log_debug "[module_exists_common] Parent directory contents: $(ls -la "$CONFIG_SOURCE_DIR/" 2>&1 || echo "Cannot list parent directory")"
        return 1
    fi
}

# Alias for backward compatibility
module_exists() {
    module_exists_common "$@"
}

# Get module path
get_module_path() {
    local module="$1"
    echo "$CONFIG_SOURCE_DIR/$module"
}

# Get the target path where a module should be installed
get_module_target_path() {
    local module="$1"
    local module_config="$CONFIG_SOURCE_DIR/$module/configz.toml"
    
    log_debug "[get_module_target_path] Getting target path for module: $module"
    log_debug "[get_module_target_path] Module config path: $module_config"
    
    # Vérifier si le fichier de configuration existe
    if [[ ! -f "$module_config" ]]; then
        local default_path="$HOME/.config/$(basename "$module")"
        log_debug "[get_module_target_path] No config file found, using default path: $default_path"
        echo "$default_path"
        return 0
    fi
    
    # Essayer de lire le chemin cible depuis le fichier de configuration
    log_debug "[get_module_target_path] Reading target from config file"
    local target_path
    target_path=$(grep -E '^target\s*=' "$module_config" | head -n 1 | cut -d '=' -f 2- | sed -e 's/^[ \t]*//' -e 's/[ \t]*$//' -e "s/^['\"]\(.*\)['\"]\?\$/\1/")
    
    log_debug "[get_module_target_path] Raw target_path from config: '$target_path'"
    
    # Si aucun chemin n'est spécifié, utiliser le chemin par défaut
    if [[ -z "$target_path" ]]; then
        local default_path="$HOME/.config/$(basename "$module")"
        log_debug "[get_module_target_path] No target specified in config, using default path: $default_path"
        echo "$default_path"
        return 0
    fi
    
    # Supprimer les guillemets éventuels et les espaces
    target_path=$(echo "$target_path" | sed -e 's/^"\(.*\)"$/\1/' -e "s/^'\([^']*\)'\$/\1/")
    
    # Remplacer ~ par $HOME
    target_path="${target_path/#\~/$HOME}"
    
    # Si le chemin est relatif, le rendre absolu par rapport à $HOME/.config
    if [[ "$target_path" != /* ]]; then
        target_path="$HOME/.config/$target_path"
    fi
    
    # Nettoyer le chemin (supprimer les //, /./, etc.)
    target_path=$(echo "$target_path" | sed 's#/\./#/#g; s#//*#/#g')
    
    log_debug "[get_module_target_path] Final target path: $target_path"
    echo "$target_path"
    return 0
}

# Vérifie si un module est installé
is_module_installed() {
    local module="$1"
    local target_path
    target_path=$(get_module_target_path "$module")
    
    log_debug "Checking if module is installed: $module"
    log_debug "Target path: $target_path"
    
    # Vérifier si la cible existe (lien symbolique ou répertoire)
    if [[ -e "$target_path" || -L "$target_path" ]]; then
        log_debug "Module '$module' is installed at $target_path"
        return 0  # Succès - le module est installé
    else
        log_debug "Module '$module' is NOT installed (not found at $target_path)"
        return 1  # Échec - le module n'est pas installé
    fi
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
    
    # Get the base name of the target path
    local target_name=$(basename "$target_path")
    
    # Create backup directory if it doesn't exist
    local backup_dir="$HOME/.config/configz/backups"
    mkdir -p "$backup_dir"
    
    # Create backup path in the configz backup directory
    local backup_path="${backup_dir}/${target_name}.backup.${timestamp}"

    # Skip backup if target is a symlink
    if [[ -L "$target_path" ]]; then
        log_debug "Skipping backup for symlink: $target_path"
        return 0
    fi

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
    
    log_info "Installing module: $module"
    log_debug "Source: $source_path"
    log_debug "Target: $target_path"
    
    # Vérifier si la source existe
    if [[ ! -d "$source_path" ]]; then
        log_error "Module source not found: $source_path"
        return 1
    fi
    
    # Vérifier si la cible existe déjà
    if [[ -e "$target_path" ]]; then
        log_warning "Target already exists: $target_path"
        if [[ $FORCE -ne 1 ]] && ! confirm "Overwrite existing target?"; then
            log_info "Skipping $module"
            return 0
        fi
        
        # Faire une sauvegarde si nécessaire
        if [[ $NO_BACKUP -eq 0 ]]; then
            create_backup "$target_path"
        fi
    fi
    
    # Créer le répertoire parent si nécessaire
    mkdir -p "$(dirname "$target_path")"
    
    # Installation avec ou sans lien symbolique
    if [[ $NO_SYMLINK -eq 1 ]]; then
        # Copie des fichiers (sans le configz.toml)
        log_info "Copying files for $module..."
        if [[ $DRY_RUN -eq 1 ]]; then
            log_info "[DRY RUN] Would copy files from $source_path to $target_path"
        else
            # Copier tous les fichiers sauf configz.toml
            if ! (cd "$source_path" && find . -type f ! -name 'configz.toml' -exec install -Dm 644 {} "$target_path/{}" \;); then
                log_error "Failed to copy files for $module"
                return 1
            fi
            log_success "Copied module '$module' to $target_path"
        fi
    else
        # Créer un lien symbolique
        log_info "Creating symlink for $module..."
        if [[ $DRY_RUN -eq 1 ]]; then
            log_info "[DRY RUN] Would create symlink: $target_path -> $source_path"
        else
            # Créer le répertoire parent si nécessaire
            mkdir -p "$(dirname "$target_path")"
            
            # Créer le lien symbolique
            ln -sf "$CONFIG_SOURCE_DIR/$module" "$target_path" || {
                log_error "Failed to create symlink for $module"
                return 1
            }
            log_success "Created symlink: $target_path -> $CONFIG_SOURCE_DIR/$module"
        fi
    fi
    
    return 0
}

# Remove module files
remove_module_files() {
    local module="$1"
    local target_path
    target_path=$(get_module_target_path "$module")
    
    log_info "Removing module: $module"
    log_debug "Target: $target_path"

    # Vérifier si le module est installé
    if [[ ! -e "$target_path" && ! -L "$target_path" ]]; then
        log_warning "Module '$module' is not installed"
        return 1
    fi
    
    # Faire une sauvegarde si nécessaire
    if [[ $NO_BACKUP -eq 0 ]]; then
        create_backup "$target_path"
    fi
    
    # Supprimer la cible (lien symbolique ou répertoire)
    if [[ $DRY_RUN -eq 1 ]]; then
        log_info "[DRY RUN] Would remove: $target_path"
    else
        if [[ -L "$target_path" ]]; then
            # Supprimer un lien symbolique
            rm -f "$target_path" || {
                log_error "Failed to remove symlink: $target_path"
                return 1
            }
            log_success "Removed symlink: $target_path"
        else
            # Supprimer un répertoire
            rm -rf "$target_path" || {
                log_error "Failed to remove directory: $target_path"
                return 1
            }
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
        # Supprimer les espaces en utilisant l'expansion arithmétique
        echo $(( $(find "$dir" -type f | wc -l) ))
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
  "version": "0.4.0-alpha",
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
