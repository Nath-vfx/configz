#!/bin/bash

# Configz - Utilities Module
# Shared utilities for extensible configuration deployment
# Version: 1.0

# =============================================================================
# COLORS AND FORMATTING
# =============================================================================

# Color codes
export RED='\033[0;31m'
export GREEN='\033[0;32m'
export YELLOW='\033[1;33m'
export BLUE='\033[0;34m'
export CYAN='\033[0;36m'
export MAGENTA='\033[0;35m'
export WHITE='\033[1;37m'
export BOLD='\033[1m'
export DIM='\033[2m'
export UNDERLINE='\033[4m'
export NC='\033[0m' # No Color

# =============================================================================
# LOGGING FUNCTIONS
# =============================================================================

# Log info message
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

# Log success message
log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

# Log warning message
log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Log error message
log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Log debug message (only if DEBUG=1)
log_debug() {
    if [[ "${DEBUG:-0}" == "1" ]]; then
        echo -e "${DIM}[DEBUG]${NC} $1"
    fi
}

# Log with custom prefix and color
log_custom() {
    local color="$1"
    local prefix="$2"
    local message="$3"
    echo -e "${color}[${prefix}]${NC} $message"
}

# =============================================================================
# SYSTEM UTILITIES
# =============================================================================

# Get script directory
get_script_dir() {
    echo "$(cd "$(dirname "${BASH_SOURCE[1]}")" && pwd)"
}

# Get project root directory
get_project_root() {
    local script_dir="$(get_script_dir)"
    # Navigate up to find the project root (directory containing lib/)
    while [[ "$script_dir" != "/" ]]; do
        if [[ -d "$script_dir/lib" ]]; then
            echo "$script_dir"
            return 0
        fi
        script_dir="$(dirname "$script_dir")"
    done
    echo "$(pwd)" # Fallback to current directory
}

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check if GUI tools are available
check_gui_available() {
    command_exists whiptail || command_exists dialog
}

# Get preferred GUI tool
get_gui_tool() {
    if command_exists whiptail; then
        echo "whiptail"
    elif command_exists dialog; then
        echo "dialog"
    else
        echo "none"
    fi
}

# =============================================================================
# FILE SYSTEM UTILITIES
# =============================================================================

# Create directory if it doesn't exist
ensure_directory() {
    local dir="$1"
    if [[ ! -d "$dir" ]]; then
        mkdir -p "$dir"
        log_debug "Created directory: $dir"
    fi
}

# Check if file exists and is readable
file_readable() {
    [[ -f "$1" && -r "$1" ]]
}

# Check if directory exists and is accessible
dir_accessible() {
    [[ -d "$1" && -r "$1" && -x "$1" ]]
}

# Get file modification time
get_file_mtime() {
    local file="$1"
    if [[ -f "$file" ]]; then
        stat -c %Y "$file" 2>/dev/null || stat -f %m "$file" 2>/dev/null
    else
        echo "0"
    fi
}

# =============================================================================
# BACKUP UTILITIES
# =============================================================================

# Create backup of a file
backup_file() {
    local file="$1"
    local backup_suffix="${2:-$(date +%Y%m%d_%H%M%S)}"

    if [[ -f "$file" ]]; then
        local backup_file="${file}.backup.${backup_suffix}"
        cp "$file" "$backup_file"
        log_info "Backup created: $backup_file"
        echo "$backup_file"
    fi
}

# Create backup of a directory
backup_directory() {
    local dir="$1"
    local backup_suffix="${2:-$(date +%Y%m%d_%H%M%S)}"

    if [[ -d "$dir" ]]; then
        local backup_dir="${dir}.backup.${backup_suffix}"
        cp -r "$dir" "$backup_dir"
        log_info "Directory backup created: $backup_dir"
        echo "$backup_dir"
    fi
}

# Restore from backup
restore_backup() {
    local backup_file="$1"
    local original_file="${backup_file%.backup.*}"

    if [[ -f "$backup_file" ]]; then
        cp "$backup_file" "$original_file"
        log_success "Restored from backup: $original_file"
    else
        log_error "Backup file not found: $backup_file"
        return 1
    fi
}

# =============================================================================
# CONFIGURATION PARSING
# =============================================================================

# Parse tools configuration file
parse_tools_config() {
    local config_file="$1"
    local output_format="${2:-array}" # array, json, or raw

    if [[ ! -f "$config_file" ]]; then
        log_error "Configuration file not found: $config_file"
        return 1
    fi

    # Filter out comments and empty lines
    local tools_data
    tools_data=$(grep -v '^\s*#' "$config_file" | grep -v '^\s*$')

    case "$output_format" in
        "array")
            echo "$tools_data"
            ;;
        "json")
            echo "$tools_data" | while IFS='|' read -r id name desc source target func; do
                echo "{\"id\":\"$id\",\"name\":\"$name\",\"description\":\"$desc\",\"source\":\"$source\",\"target\":\"$target\",\"function\":\"$func\"}"
            done | jq -s '.'
            ;;
        "raw")
            echo "$tools_data"
            ;;
    esac
}

# Get tool info by ID
get_tool_info() {
    local tool_id="$1"
    local config_file="$2"
    local field="${3:-all}" # id, name, description, source, target, function, or all

    local tool_line
    tool_line=$(parse_tools_config "$config_file" | grep "^$tool_id|")

    if [[ -z "$tool_line" ]]; then
        log_error "Tool not found: $tool_id"
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
    esac
}

# List available tools
list_tools() {
    local config_file="$1"
    local format="${2:-simple}" # simple, detailed, or ids

    case "$format" in
        "simple")
            parse_tools_config "$config_file" | cut -d'|' -f1,2
            ;;
        "detailed")
            parse_tools_config "$config_file"
            ;;
        "ids")
            parse_tools_config "$config_file" | cut -d'|' -f1
            ;;
    esac
}

# =============================================================================
# INSTALLATION UTILITIES
# =============================================================================

# Check if tool is installed/configured
is_tool_configured() {
    local tool_id="$1"
    local config_file="$2"
    local target_path

    target_path=$(get_tool_info "$tool_id" "$config_file" "target")
    if [[ -z "$target_path" ]]; then
        return 1
    fi

    local full_target_path="$HOME/$target_path"

    # Check if target exists (file or directory)
    [[ -e "$full_target_path" ]]
}

# Get installation status for all tools
get_installation_status() {
    local config_file="$1"

    while read -r tool_id _; do
        if is_tool_configured "$tool_id" "$config_file"; then
            echo "$tool_id|installed"
        else
            echo "$tool_id|not_installed"
        fi
    done < <(list_tools "$config_file" "ids" | sed 's/|.*//')
}

# =============================================================================
# USER INTERACTION UTILITIES
# =============================================================================

# Ask yes/no question
ask_yes_no() {
    local question="$1"
    local default="${2:-n}" # y or n

    local prompt
    if [[ "$default" == "y" ]]; then
        prompt="[Y/n]"
    else
        prompt="[y/N]"
    fi

    echo -e -n "${CYAN}$question ${prompt}${NC} "
    read -r response

    case "$response" in
        [Yy]|[Yy][Ee][Ss]) return 0 ;;
        [Nn]|[Nn][Oo]) return 1 ;;
        "") [[ "$default" == "y" ]] && return 0 || return 1 ;;
        *) ask_yes_no "$question" "$default" ;;
    esac
}

# Show progress bar
show_progress() {
    local current="$1"
    local total="$2"
    local message="${3:-Processing}"
    local width=50

    local percentage=$((current * 100 / total))
    local filled=$((current * width / total))
    local empty=$((width - filled))

    printf "\r${BLUE}%s${NC} [" "$message"
    printf "%*s" "$filled" | tr ' ' '█'
    printf "%*s" "$empty" | tr ' ' '░'
    printf "] %d%%" "$percentage"

    if [[ "$current" -eq "$total" ]]; then
        echo
    fi
}

# =============================================================================
# VALIDATION UTILITIES
# =============================================================================

# Validate tool ID format
validate_tool_id() {
    local tool_id="$1"

    # Tool ID should be alphanumeric with optional underscores/hyphens
    if [[ "$tool_id" =~ ^[a-zA-Z0-9_-]+$ ]]; then
        return 0
    else
        log_error "Invalid tool ID format: $tool_id"
        return 1
    fi
}

# Validate configuration file format
validate_config_file() {
    local config_file="$1"
    local errors=0

    if [[ ! -f "$config_file" ]]; then
        log_error "Configuration file not found: $config_file"
        return 1
    fi

    local line_num=0
    while IFS= read -r line; do
        ((line_num++))

        # Skip comments and empty lines
        if [[ "$line" =~ ^[[:space:]]*# ]] || [[ -z "${line// }" ]]; then
            continue
        fi

        # Check format: should have exactly 6 fields separated by |
        local field_count
        field_count=$(echo "$line" | grep -o '|' | wc -l)

        if [[ "$field_count" -ne 5 ]]; then
            log_error "Line $line_num: Invalid format (expected 6 fields, got $((field_count + 1)))"
            ((errors++))
        fi

        # Validate tool ID
        local tool_id
        tool_id=$(echo "$line" | cut -d'|' -f1)
        if ! validate_tool_id "$tool_id"; then
            log_error "Line $line_num: Invalid tool ID: $tool_id"
            ((errors++))
        fi
    done < "$config_file"

    if [[ "$errors" -gt 0 ]]; then
        log_error "Configuration file has $errors error(s)"
        return 1
    fi

    log_success "Configuration file validation passed"
    return 0
}

# =============================================================================
# UTILITY INITIALIZATION
# =============================================================================

# Initialize utilities (call this in main scripts)
init_utils() {
    # Set up error handling
    set -euo pipefail

    # Set up debug mode if requested
    if [[ "${DEBUG:-0}" == "1" ]]; then
        set -x
        log_debug "Debug mode enabled"
    fi

    # Export utility functions for use in subshells
    export -f log_info log_success log_warning log_error log_debug
    export -f command_exists ensure_directory backup_file backup_directory
}

# Print utility information
print_utils_info() {
    echo -e "${BOLD}${CYAN}Configz Utils Library${NC}"
    echo -e "${DIM}Shared utilities for extensible configuration deployment${NC}"
    echo
    echo -e "${BOLD}Available functions:${NC}"
    echo -e "  • Logging: log_info, log_success, log_warning, log_error"
    echo -e "  • System: command_exists, check_gui_available, get_gui_tool"
    echo -e "  • Files: backup_file, backup_directory, ensure_directory"
    echo -e "  • Config: parse_tools_config, get_tool_info, list_tools"
    echo -e "  • User: ask_yes_no, show_progress"
    echo -e "  • Validation: validate_tool_id, validate_config_file"
    echo
}

# Check if script is being run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    print_utils_info
fi
