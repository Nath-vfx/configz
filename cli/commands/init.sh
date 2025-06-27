#!/usr/bin/env bash

# Configz - Init Command
# Initialize a new configuration module

# Source common library
# shellcheck source=../lib/common.sh
source "$CLI_DIR/lib/common.sh"

# =============================================================================
# INIT COMMAND FUNCTIONS
# =============================================================================

show_init_help() {
    cat << EOF
$PROGRAM_NAME init - Initialize a new configuration module

USAGE:
    $PROGRAM_NAME init [OPTIONS] <module_name>

OPTIONS:
    -h, --help          Show this help message
    -d, --description    Module description (enclosed in quotes if it contains spaces)
    -a, --author        Author name (default: current user)
    -v, --version       Module version (default: 0.1.0)
    -i, --icon          Emoji icon for the module (default: 📦)
    --no-config         Don't create a configz.toml file
    --overwrite         Overwrite existing module (requires confirmation)

EXAMPLES:
    $PROGRAM_NAME init my-module
    $PROGRAM_NAME init my-module --description "My awesome config"
    $PROGRAM_NAME init my-module --author "John Doe" --version "1.0.0"
    $PROGRAM_NAME init my-module --icon "🚀"

DESCRIPTION:
    Creates a new configuration module with the specified name and optional metadata.
    By default, it creates a basic configz.toml file with the provided information.

EOF
}

# Check if module already exists and handle overwrite
module_exists() {
    local module_name="$1"
    local module_dir="$CONFIG_SOURCE_DIR/$module_name"
    local overwrite="${2:-false}"
    
    # Check for case-insensitive match first (important for case-insensitive filesystems)
    local existing_module
    existing_module=$(find "$CONFIG_SOURCE_DIR" -maxdepth 1 -iname "$module_name" -type d -print -quit 2>/dev/null)
    
    # Handle case where module name differs only by case
    if [[ -n "$existing_module" && "$(basename "$existing_module")" != "$module_name" ]]; then
        log_error "A module with a similar name already exists: $(basename "$existing_module")"
        log_info "Module names are case-insensitive. Please choose a different name."
        return 1
    fi
    
    # If module doesn't exist, no need to check for overwrite
    if [[ ! -d "$module_dir" ]]; then
        return 0
    fi
    
    # If we get here, the module exists
    if [[ "$overwrite" != "true" ]]; then
        log_error "Module '$module_name' already exists in $CONFIG_SOURCE_DIR"
        log_info "Use --overwrite to replace the existing module"
        log_info "Or remove it first with: $PROGRAM_NAME remove $module_name"
        return 1
    fi
    
    # If we're overwriting, ask for confirmation
    # Use stderr for the prompt to separate it from stdout
    echo -e "\n\e[33mWARNING: This will create a backup and replace the existing module '$module_name'.\e[0m" >&2
    echo -e "\e[33mAll existing files in '$module_dir' will be moved to backup.\e[0m" >&2
    echo -n "Continue? [y/N] " >&2
    
    # Read from stderr to avoid mixing with stdout
    read -r confirm < /dev/tty
    
    if [[ ! "$confirm" =~ ^[Yy]([Ee][Ss])?$ ]]; then
        echo "Operation cancelled by user" >&2
        return 1
    fi
    
    # Create backup of existing module before removal
    local backup_dir="$HOME/.config/configz/backups"
    mkdir -p "$backup_dir"
    
    # Create a timestamp for the backup
    local timestamp
    timestamp=$(date +"%Y%m%d_%H%M%S")
    local backup_name="${module_name}.backup.${timestamp}"
    local backup_path="${backup_dir}/${backup_name}"
    
    # Create the backup
    if cp -r "$module_dir" "$backup_path" 2>/dev/null; then
        echo -e "\e[32m✓ Created backup: $backup_name\e[0m" >&2
        echo -e "  Backup location: $backup_path" >&2
    else
        echo -e "\e[33m✗ Failed to create backup of existing module\e[0m" >&2
        echo -n "Continue without backup? (not recommended) [y/N] " >&2
        
        read -r confirm < /dev/tty
        
        if [[ ! "$confirm" =~ ^[Yy]([Ee][Ss])?$ ]]; then
            echo "Operation cancelled by user" >&2
            return 1
        fi
    fi
    
    # Remove existing module
    if ! rm -rf "$module_dir"; then
        echo -e "\e[31m✗ Failed to remove existing module: $module_dir\e[0m" >&2
        return 1
    fi
    
    echo -e "\e[33m✓ Removed existing module: $module_name\e[0m" >&2
    return 0
}

# Validate module name
validate_module_name() {
    local module_name="$1"
    
    # Check if name is empty
    if [[ -z "$module_name" ]]; then
        log_error "Module name cannot be empty"
        return 1
    fi
    
    # Check for invalid characters
    if [[ ! "$module_name" =~ ^[a-zA-Z0-9_-]+$ ]]; then
        log_error "Invalid module name: $module_name"
        log_info "Module name can only contain letters, numbers, hyphens, and underscores"
        return 1
    fi
    
    # Check for reserved names
    local reserved_names=("configz" "system" "core" "shared" "common")
    for name in "${reserved_names[@]}"; do
        if [[ "${module_name,,}" == "${name,,}" ]]; then
            log_error "'$module_name' is a reserved module name"
            return 1
        fi
    done
    
    # Check for hidden modules (starting with .) unless explicitly allowed
    if [[ "$module_name" == .* && "$module_name" != "." && "$module_name" != ".." ]]; then
        log_error "Module name cannot start with a dot (.)"
        log_info "Hidden modules are not allowed as they are typically used for system purposes"
        return 1
    fi
    
    # Check length
    if [[ ${#module_name} -gt 50 ]]; then
        log_error "Module name is too long (max 50 characters)"
        return 1
    fi
    
    return 0
}

# Create basic module structure
create_module_structure() {
    local module_name="$1"
    local overwrite="${2:-false}"
    local module_dir="$CONFIG_SOURCE_DIR/$module_name"
    
    # Check if module already exists and handle overwrite
    if ! module_exists "$module_name" "$overwrite"; then
        return 1
    fi
    
    # Validate module name
    if ! validate_module_name "$module_name"; then
        return 1
    fi
    
    # Create parent directory if it doesn't exist
    if [[ ! -d "$CONFIG_SOURCE_DIR" ]]; then
        mkdir -p "$CONFIG_SOURCE_DIR" || {
            echo -e "\e[31m✗ Failed to create config directory: $CONFIG_SOURCE_DIR\e[0m" >&2
            return 1
        }
    fi
    
    # Create module directory
    if ! mkdir -p "$module_dir"; then
        echo -e "\e[31m✗ Failed to create module directory: $module_dir\e[0m" >&2
        echo -e "  Check if you have sufficient permissions to write to: $(dirname "$module_dir")" >&2
        return 1
    fi
    
    # Output the module directory path (this is captured by the caller)
    echo "$module_dir"
    return 0
}

# Create basic configz.toml
create_config_file() {
    local module_dir="$1"
    local module_name="$(basename "$module_dir")"
    local description="${2:-Configuration for $module_name}"
    local author="${3:-$(whoami)}"
    local version="${4:-0.1.0}"
    local icon="${5:-📦}"
    
    local config_file="$module_dir/configz.toml"
    
    # Ensure the directory exists
    mkdir -p "$module_dir" || {
        log_error "Failed to create module directory: $module_dir"
        return 1
    }
    
    # Create config file with proper error handling
    if ! cat > "$config_file" 2>/dev/null << EOF
[module]
name = "$module_name"
description = "$description"
icon = "$icon"
version = "$version"
author = "$author"

[installation]
type = "symlink"  # or "copy"

[paths]
target = "$module_name"
sources = [
    # List of files/directories to include
    # "config.conf",
    # "themes/",
]

[dependencies]
# system = ["required_command1", "required_command2"]
# modules = ["other_module1", "other_module2"]

[post_install]
notes = [
    # Add any post-installation notes here
    # "Restart your terminal after installation",
]
EOF
    then
        log_error "Failed to create config file: $config_file"
        log_info "Check if you have write permissions in: $module_dir"
        return 1
    fi
    
    log_success "Created configuration file: $config_file"
    return 0
}

# =============================================================================
# MAIN COMMAND FUNCTION
# =============================================================================

init_main() {
    local module_name=""
    local description=""
    local author=""
    local version=""
    local icon=""
    local create_config=true
    local overwrite=false
    
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -h|--help)
                show_init_help
                return 0
                ;;
            -d|--description)
                description="$2"
                shift 2
                ;;
            -a|--author)
                author="$2"
                shift 2
                ;;
            -v|--version)
                version="$2"
                shift 2
                ;;
            -i|--icon)
                icon="$2"
                shift 2
                ;;
            --no-config)
                create_config=false
                shift
                ;;
            --overwrite)
                overwrite=true
                shift
                ;;
            -*)
                log_error "Unknown option: $1"
                log_info "Use '$PROGRAM_NAME init --help' for available options"
                return 1
                ;;
            *)
                if [[ -z "$module_name" ]]; then
                    module_name="$1"
                    shift
                else
                    log_error "Unexpected argument: $1"
                    log_info "Use '$PROGRAM_NAME init --help' for usage information"
                    return 1
                fi
                ;;
        esac
    done
    
    # Validate module name
    if [[ -z "$module_name" ]]; then
        log_error "Module name is required"
        log_info "Use '$PROGRAM_NAME init --help' for usage information"
        return 1
    fi
    
    # Validate module name
    if ! validate_module_name "$module_name"; then
        return 1
    fi
    
    # Only show overwrite message if the module actually exists
    if [[ -d "$CONFIG_SOURCE_DIR/$module_name" && "$overwrite" == "true" ]]; then
        echo -e "\n\e[36mReinitializing module: $module_name (overwriting existing)\e[0m" >&2
    else
        echo -e "\n\e[36mInitializing new module: $module_name\e[0m" >&2
    fi
    
    # Run create_module_structure
    local module_dir
    module_dir=$(create_module_structure "$module_name" "$overwrite")
    
    # Verify the directory was created
    if [[ ! -d "$module_dir" ]]; then
        log_error "Failed to create module directory: $module_dir"
        return 1
    fi
    
    log_success "✓ Module directory created: $module_dir"
    
    # Create config file if requested
    if [[ "$create_config" == true ]]; then
        if ! create_config_file "$module_dir" "$description" "$author" "$version" "$icon"; then
            log_warning "Continuing without configuration file"
        fi
    fi
    
    # Display success message with next steps
    echo -e "\n${GREEN}✓ Module '$module_name' successfully initialized!${NC}"
    echo -e "\n${BOLD}Next steps:${NC}"
    
    # Create a bullet point function for consistent formatting
    local bullet="${BOLD}•${NC} "
    
    echo -e "${bullet}Add your configuration files to:"
    echo -e "  ${DIM}$module_dir${NC}\n"
    
    if [[ "$create_config" == true ]]; then
        echo -e "${bullet}Edit the module configuration:"
        echo -e "  ${DIM}$module_dir/configz.toml${NC}\n"
    else
        echo -e "${bullet}Create a configuration file:"
        echo -e "  ${DIM}$module_dir/configz.toml${NC}\n"
    fi
    
    echo -e "${bullet}Install the module:"
    echo -e "  ${BOLD}$PROGRAM_NAME install $module_name${NC}\n"
    
    echo -e "${DIM}For more information, run: $PROGRAM_NAME --help${NC}"
    
    return 0
}
