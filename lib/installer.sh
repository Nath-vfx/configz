#!/bin/bash

# Configz - Extensible Installer Module
# Dynamic tool installation system with plugin support
# Version: 1.0

# =============================================================================
# MODULE INITIALIZATION
# =============================================================================

# Get current script directory and project root
INSTALLER_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$INSTALLER_DIR")"

# Source utilities if available
if [[ -f "$INSTALLER_DIR/utils.sh" ]]; then
    source "$INSTALLER_DIR/utils.sh"
else
    # Fallback logging functions
    log_info() { echo "[INFO] $1"; }
    log_success() { echo "[SUCCESS] $1"; }
    log_warning() { echo "[WARNING] $1"; }
    log_error() { echo "[ERROR] $1"; }
fi

# =============================================================================
# CONFIGURATION
# =============================================================================

# Default paths
TOOLS_CONFIG_FILE="${PROJECT_ROOT}/lib/tools.conf"
CONFIG_SOURCE_DIR="${PROJECT_ROOT}/config"
TARGET_BASE_DIR="$HOME"

# Installation options
BACKUP_ENABLED=1
DRY_RUN=0
VERBOSE=0
FORCE_INSTALL=0

# =============================================================================
# CORE INSTALLER FUNCTIONS
# =============================================================================

# Initialize installer
init_installer() {
    log_info "Initializing Configz Installer..."

    # Validate required files
    if [[ ! -f "$TOOLS_CONFIG_FILE" ]]; then
        log_error "Tools configuration file not found: $TOOLS_CONFIG_FILE"
        return 1
    fi

    if [[ ! -d "$CONFIG_SOURCE_DIR" ]]; then
        log_error "Configuration source directory not found: $CONFIG_SOURCE_DIR"
        return 1
    fi

    # Validate configuration file
    if command -v validate_config_file >/dev/null 2>&1; then
        validate_config_file "$TOOLS_CONFIG_FILE" || return 1
    fi

    # Ensure target base directory exists
    ensure_directory "$TARGET_BASE_DIR/.config"

    log_success "Installer initialized successfully"
}

# Get available tools from configuration
get_available_tools() {
    if command -v parse_tools_config >/dev/null 2>&1; then
        parse_tools_config "$TOOLS_CONFIG_FILE" | cut -d'|' -f1
    else
        # Fallback: parse manually
        grep -v '^\s*#' "$TOOLS_CONFIG_FILE" | grep -v '^\s*$' | cut -d'|' -f1
    fi
}

# Get tool configuration
get_tool_config() {
    local tool_id="$1"
    local field="${2:-all}"

    local tool_line
    tool_line=$(grep "^$tool_id|" "$TOOLS_CONFIG_FILE" | head -1)

    if [[ -z "$tool_line" ]]; then
        log_error "Tool configuration not found: $tool_id"
        return 1
    fi

    IFS='|' read -r id name desc source target func <<< "$tool_line"

    case "$field" in
        "id") echo "$id" ;;
        "name") echo "$name" ;;
        "description") echo "$desc" ;;
        "source") echo "$source" ;;
        "target") echo "$target" ;;
        "function") echo "$func" ;;
        "all") echo "$tool_line" ;;
        *) log_error "Invalid field: $field"; return 1 ;;
    esac
}

# Check if tool source exists
tool_source_exists() {
    local tool_id="$1"
    local source_path

    source_path=$(get_tool_config "$tool_id" "source")
    [[ -n "$source_path" && -e "$PROJECT_ROOT/$source_path" ]]
}

# Check if tool is already installed
is_tool_installed() {
    local tool_id="$1"
    local target_path

    target_path=$(get_tool_config "$tool_id" "target")
    [[ -n "$target_path" && -e "$TARGET_BASE_DIR/$target_path" ]]
}

# =============================================================================
# INSTALLATION FUNCTIONS
# =============================================================================

# Generic install function for simple file/directory copy
install_generic() {
    local tool_id="$1"
    local source_path target_path full_source full_target

    source_path=$(get_tool_config "$tool_id" "source")
    target_path=$(get_tool_config "$tool_id" "target")

    if [[ -z "$source_path" || -z "$target_path" ]]; then
        log_error "Invalid configuration for tool: $tool_id"
        return 1
    fi

    full_source="$PROJECT_ROOT/$source_path"
    full_target="$TARGET_BASE_DIR/$target_path"

    # Check if source exists
    if [[ ! -e "$full_source" ]]; then
        log_error "Source not found: $full_source"
        return 1
    fi

    # Create target directory
    ensure_directory "$(dirname "$full_target")"

    # Backup existing configuration if enabled
    if [[ "$BACKUP_ENABLED" -eq 1 && -e "$full_target" ]]; then
        if command -v backup_file >/dev/null 2>&1 && [[ -f "$full_target" ]]; then
            backup_file "$full_target"
        elif command -v backup_directory >/dev/null 2>&1 && [[ -d "$full_target" ]]; then
            backup_directory "$full_target"
        fi
    fi

    # Perform installation
    if [[ "$DRY_RUN" -eq 1 ]]; then
        log_info "[DRY RUN] Would copy: $full_source -> $full_target"
    else
        log_info "Installing $tool_id: $source_path -> $target_path"
        cp -r "$full_source"/* "$full_target/" 2>/dev/null || cp -r "$full_source" "$full_target"
        log_success "Successfully installed $tool_id"
    fi
}

# Install Fish Shell configuration
install_fish() {
    local tool_id="fish"
    local target_dir="$TARGET_BASE_DIR/.config/fish"

    log_info "Installing Fish Shell configuration..."

    ensure_directory "$target_dir"

    if [[ "$BACKUP_ENABLED" -eq 1 && -f "$target_dir/config.fish" ]]; then
        backup_file "$target_dir/config.fish"
    fi

    if [[ "$DRY_RUN" -eq 0 ]]; then
        cp "$PROJECT_ROOT/config/fish/config.fish" "$target_dir/config.fish"
        log_success "Fish configuration installed"
    else
        log_info "[DRY RUN] Would install Fish configuration"
    fi
}

# Install Ghostty Terminal configuration
install_ghostty() {
    local tool_id="ghostty"
    local target_dir="$TARGET_BASE_DIR/.config/ghostty"

    log_info "Installing Ghostty Terminal configuration..."

    ensure_directory "$target_dir"
    ensure_directory "$target_dir/theme"

    if [[ "$BACKUP_ENABLED" -eq 1 && -d "$target_dir" && "$(ls -A "$target_dir")" ]]; then
        backup_directory "$target_dir"
    fi

    if [[ "$DRY_RUN" -eq 0 ]]; then
        cp "$PROJECT_ROOT/config/ghostty/config" "$target_dir/config"
        cp "$PROJECT_ROOT/config/ghostty/theme/main" "$target_dir/theme/main"
        log_success "Ghostty configuration installed"
    else
        log_info "[DRY RUN] Would install Ghostty configuration"
    fi
}

# Install Starship Prompt configuration
install_starship() {
    local tool_id="starship"
    local target_dir="$TARGET_BASE_DIR/.config/starship"

    log_info "Installing Starship Prompt configuration..."

    ensure_directory "$target_dir"

    if [[ "$BACKUP_ENABLED" -eq 1 && -f "$target_dir/starship.toml" ]]; then
        backup_file "$target_dir/starship.toml"
    fi

    if [[ "$DRY_RUN" -eq 0 ]]; then
        cp "$PROJECT_ROOT/config/starship/starship.toml" "$target_dir/starship.toml"
        log_success "Starship configuration installed"
    else
        log_info "[DRY RUN] Would install Starship configuration"
    fi
}

# =============================================================================
# DYNAMIC INSTALLER
# =============================================================================

# Install a single tool by ID
install_tool() {
    local tool_id="$1"
    local install_func

    # Validate tool exists
    if ! tool_source_exists "$tool_id"; then
        log_error "Tool source not found: $tool_id"
        return 1
    fi

    # Check if already installed and not forcing
    if [[ "$FORCE_INSTALL" -eq 0 ]] && is_tool_installed "$tool_id"; then
        log_warning "Tool already installed: $tool_id (use --force to reinstall)"
        return 0
    fi

    # Get install function
    install_func=$(get_tool_config "$tool_id" "function")

    if [[ -z "$install_func" ]]; then
        log_error "No install function specified for: $tool_id"
        return 1
    fi

    # Check if install function exists
    if command -v "$install_func" >/dev/null 2>&1; then
        log_info "Installing $tool_id using $install_func..."
        "$install_func"
    else
        log_warning "Install function not found: $install_func, using generic installer"
        install_generic "$tool_id"
    fi
}

# Install multiple tools
install_tools() {
    local tools=("$@")
    local total=${#tools[@]}
    local current=0
    local failed=()

    log_info "Installing $total tool(s)..."

    for tool_id in "${tools[@]}"; do
        ((current++))

        if command -v show_progress >/dev/null 2>&1; then
            show_progress "$current" "$total" "Installing tools"
        fi

        if install_tool "$tool_id"; then
            log_success "✓ $tool_id installed successfully"
        else
            log_error "✗ Failed to install $tool_id"
            failed+=("$tool_id")
        fi
    done

    # Summary
    local success_count=$((total - ${#failed[@]}))
    log_info "Installation complete: $success_count/$total successful"

    if [[ ${#failed[@]} -gt 0 ]]; then
        log_warning "Failed installations: ${failed[*]}"
        return 1
    fi
}

# Install all available tools
install_all() {
    local tools
    mapfile -t tools < <(get_available_tools)

    log_info "Installing all available tools: ${tools[*]}"
    install_tools "${tools[@]}"
}

# =============================================================================
# UTILITY FUNCTIONS
# =============================================================================

# List available tools with status
list_tools_status() {
    local tools
    mapfile -t tools < <(get_available_tools)

    echo -e "${BOLD}Available Tools:${NC}"
    echo

    for tool_id in "${tools[@]}"; do
        local name desc status_icon status_text

        name=$(get_tool_config "$tool_id" "name")
        desc=$(get_tool_config "$tool_id" "description")

        if is_tool_installed "$tool_id"; then
            status_icon="✅"
            status_text="${GREEN}Installed${NC}"
        else
            status_icon="⭕"
            status_text="${YELLOW}Not installed${NC}"
        fi

        echo -e "  $status_icon ${BOLD}$name${NC}"
        echo -e "     ${DIM}$desc${NC}"
        echo -e "     Status: $status_text"
        echo
    done
}

# Show installation summary
show_install_summary() {
    local installed_tools=()
    local available_tools

    mapfile -t available_tools < <(get_available_tools)

    for tool_id in "${available_tools[@]}"; do
        if is_tool_installed "$tool_id"; then
            installed_tools+=("$tool_id")
        fi
    done

    echo -e "${BOLD}${CYAN}Installation Summary${NC}"
    echo "===================="
    echo "Total tools available: ${#available_tools[@]}"
    echo "Installed tools: ${#installed_tools[@]}"
    echo

    if [[ ${#installed_tools[@]} -gt 0 ]]; then
        echo -e "${BOLD}Installed configurations:${NC}"
        for tool_id in "${installed_tools[@]}"; do
            local name target
            name=$(get_tool_config "$tool_id" "name")
            target=$(get_tool_config "$tool_id" "target")
            echo "  • $name: ~/$target"
        done
        echo
    fi
}

# =============================================================================
# MAIN FUNCTION
# =============================================================================

# Main installer function
main_installer() {
    local action="${1:-help}"
    shift || true

    case "$action" in
        "init")
            init_installer
            ;;
        "list")
            list_tools_status
            ;;
        "install")
            init_installer || return 1
            if [[ $# -eq 0 ]]; then
                install_all
            else
                install_tools "$@"
            fi
            show_install_summary
            ;;
        "status")
            init_installer || return 1
            show_install_summary
            ;;
        "help"|*)
            echo -e "${BOLD}Configz Installer Module${NC}"
            echo
            echo "Usage: $0 <action> [options]"
            echo
            echo "Actions:"
            echo "  init                 Initialize installer"
            echo "  list                 List available tools"
            echo "  install [tools...]   Install specific tools or all if none specified"
            echo "  status               Show installation status"
            echo "  help                 Show this help"
            echo
            echo "Environment Variables:"
            echo "  BACKUP_ENABLED=0     Disable backups"
            echo "  DRY_RUN=1           Show what would be done"
            echo "  VERBOSE=1           Enable verbose output"
            echo "  FORCE_INSTALL=1     Force reinstall existing tools"
            ;;
    esac
}

# Check if script is being run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main_installer "$@"
fi
