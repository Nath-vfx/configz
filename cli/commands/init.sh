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
    $PROGRAM_NAME init <module_name>

ARGUMENTS:
    module_name    Name of the module to create (required)
                 Must contain only letters, numbers, hyphens, and underscores

DESCRIPTION:
    Creates a new configuration module with the specified name.
    A basic configz.toml file will be created with default values.

EXAMPLE:
    $PROGRAM_NAME init my-module

NOTES:
    - The module name cannot be empty
    - Only alphanumeric characters, hyphens and underscores are allowed
    - The module will be created in: $CONFIG_SOURCE_DIR/

EOF
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
    local module_dir="$CONFIG_SOURCE_DIR/$module_name"
    
    log_debug "Creating module directory: $module_dir"
    
    # Create parent directory if it doesn't exist
    if [[ ! -d "$CONFIG_SOURCE_DIR" ]]; then
        log_debug "Creating CONFIG_SOURCE_DIR: $CONFIG_SOURCE_DIR"
        mkdir -p "$CONFIG_SOURCE_DIR" || {
            log_error "Failed to create config directory: $CONFIG_SOURCE_DIR"
            return 1
        }
    fi
    
    # Create module directory
    if ! mkdir -p "$module_dir"; then
        log_error "Failed to create module directory: $module_dir"
        return 1
    fi
    
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
    
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -h|--help)
                show_init_help
                return 0
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
    
    # Check if module name is provided
    if [[ -z "$module_name" ]]; then
        log_error "Module name is required"
        log_info "Use '$PROGRAM_NAME init --help' for usage information"
        return 1
    fi
    
    # Validate module name format
    if ! validate_module_name "$module_name"; then
        return 1
    fi
    
    echo -e "\n\e[36mInitializing new module: $module_name\e[0m"
    
    # Run create_module_structure
    local module_dir
    module_dir=$(create_module_structure "$module_name")
    
    # Verify the directory was created
    if [[ ! -d "$module_dir" ]]; then
        log_error "Failed to create module directory: $module_dir"
        return 1
    fi
    
    log_success "✓ Module directory created: $module_dir"
    
    # Create config file
    if ! create_config_file "$module_dir"; then
        log_warning "Failed to create config file"
        return 1
    fi
    
    echo -e "\n${GREEN}✓ Module '$module_name' successfully initialized!${NC}"
    echo -e "\n${BOLD}Next steps:${NC}"
    echo -e "  • Add your configuration files to: $module_dir"
    echo -e "  • Edit the module configuration: $module_dir/configz.toml"
    echo -e "  • Install the module: $PROGRAM_NAME install $module_name\n"
    
    return 0
}
