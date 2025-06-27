#!/usr/bin/env bash

# =============================================================================
# CONFIGZ DOCTOR COMMAND
# =============================================================================

# Set default CONFIGZ_HOME if not already set
export CONFIGZ_HOME="${CONFIGZ_HOME:-$HOME/.config/configz}"
# Checks the health of Configz installation and dependencies

# Check if output is a terminal
if [ -t 1 ]; then
    # Colors for terminal output
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    BLUE='\033[0;34m'
    BOLD='\033[1m'
    NC='\033[0m' # No Color
else
    # No colors for non-terminal output
    RED=''
    GREEN=''
    YELLOW=''
    BLUE=''
    BOLD=''
    NC=''
fi

# Source common functions
source "$CLI_DIR/lib/common.sh"

# =============================================================================
# CONSTANTS AND CONFIGURATION
# =============================================================================

# Severity levels
SEVERITY_INFO=0
SEVERITY_WARNING=1
SEVERITY_ERROR=2

# Couleurs
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color
BOLD='\033[1m'

# =============================================================================
# FONCTIONS D'AFFICHAGE
# =============================================================================

# Display a diagnostic message
# $1: severity level (0=info, 1=warning, 2=error)
# $2: message to display
# $3: recommended solution (optional)
print_diagnostic() {
    local severity="$1"
    local message="$2"
    local solution="${3:-}"
    
    case $severity in
        $SEVERITY_INFO)
            echo -e "${BLUE}ℹ INFO:${NC} $message"
            ;;
        $SEVERITY_WARNING)
            echo -e "${YELLOW}⚠ WARNING:${NC} $message"
            ;;
        $SEVERITY_ERROR)
            echo -e "${RED}✖ ERROR:${NC} $message"
            ;;
    esac
    
    if [[ -n "$solution" ]]; then
        echo -e "   ${BOLD}Suggestion:${NC} $solution"
    fi
    echo
}

# Display a check result
# $1: message
# $2: status (true/false)
# $3: error message (optional)
# $4: recommended solution (optional)
check_result() {
    local message="$1"
    local status="$2"
    local error_msg="${3:-}"
    local solution="${4:-}"
    
    if [[ "$status" == "true" ]]; then
        echo -e "${GREEN}✓${NC} $message"
    else
        if [[ -n "$error_msg" ]]; then
            print_diagnostic "$SEVERITY_ERROR" "$error_msg" "$solution"
        else
            print_diagnostic "$SEVERITY_ERROR" "Check failed: $message" "$solution"
        fi
    fi
}

# =============================================================================
# VÉRIFICATIONS
# =============================================================================

# Check system dependencies
check_system_deps() {
    local deps=("bash" "git" "rsync" "tar" "gzip")
    local missing_deps=()
    
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" >/dev/null 2>&1; then
            missing_deps+=("$dep")
        fi
    done
    
    if [[ ${#missing_deps[@]} -eq 0 ]]; then
        check_result "All system dependencies are installed" true
        return 0
    else
        local missing_list=$(IFS=", "; echo "${missing_deps[*]}")
        check_result "" false "Missing dependencies: $missing_list" \
            "Install missing dependencies using your package manager (e.g., apt, brew, etc.)"
        return 1
    fi
}

# Check directory structure
check_directories() {
    local dirs=("$CONFIG_SOURCE_DIR" "$TARGET_BASE_DIR")
    local missing_dirs=()
    
    for dir in "${dirs[@]}"; do
        if [[ ! -d "$dir" ]]; then
            missing_dirs+=("$dir")
        fi
    done
    
    if [[ ${#missing_dirs[@]} -eq 0 ]]; then
        check_result "Directory structure is correct" true
        return 0
    else
        local missing_list=$(IFS=", "; echo "${missing_dirs[*]}")
        check_result "" false "Missing directories: $missing_list" \
            "Run 'configz init' to initialize the directory structure"
        return 1
    fi
}

# Check permissions
check_permissions() {
    local errors=0
    
    # Check write permissions on important directories
    if [[ ! -w "$CONFIG_SOURCE_DIR" ]]; then
        check_result "" false "No write access to: $CONFIG_SOURCE_DIR" \
            "Check directory permissions with 'ls -ld $CONFIG_SOURCE_DIR'"
        errors=$((errors + 1))
    fi
    
    if [[ ! -w "$TARGET_BASE_DIR" ]]; then
        check_result "" false "No write access to: $TARGET_BASE_DIR" \
            "Check directory permissions with 'ls -ld $TARGET_BASE_DIR'"
        errors=$((errors + 1))
    fi
    
    if [[ $errors -eq 0 ]]; then
        check_result "Directory permissions are correct" true
        return 0
    else
        return 1
    fi
}

# Check Configz installation
check_installation() {
    local errors=0
    
    # Check if binary is in PATH
    if ! command -v "$PROGRAM_NAME" >/dev/null 2>&1; then
        check_result "" false "$PROGRAM_NAME binary is not in PATH" \
            "Add the installation directory to PATH or reinstall Configz"
        errors=$((errors + 1))
    fi
    
    # Check version
    local version_output
    version_output=$("$PROGRAM_NAME" --version 2>&1)
    if [[ $? -ne 0 ]]; then
        check_result "" false "Failed to execute '$PROGRAM_NAME --version'" \
            "Check Configz installation"
        errors=$((errors + 1))
    fi
    
    if [[ $errors -eq 0 ]]; then
        check_result "Configz installation is valid (Version: $version_output)" true
        return 0
    else
        return 1
    fi
}

# Check installed modules
check_modules() {
    local module_count=0
    local installed_count=0
    
    # Source common functions if not already sourced
    if ! declare -f is_module_installed >/dev/null; then
        source "$CLI_DIR/lib/common.sh"
    fi
    
    # List of known modules to check
    local known_modules=("starship" "fish" "ghostty")
    
    echo "Checking modules..."
    
    # Check each known module
    for module in "${known_modules[@]}"; do
        if is_module_installed "$module"; then
            local target_path
            target_path=$(get_module_target_path "$module" 2>/dev/null || echo "unknown location")
            echo "✓ $module is installed at $target_path"
            ((installed_count++))
        else
            echo "○ $module is not installed (not an error)"
        fi
        ((module_count++))
    done
    
    # Print summary
    echo
    if [[ $installed_count -gt 0 ]]; then
        echo "Found $installed_count of $module_count modules installed"
    else
        echo "No modules installed (this is normal if you haven't installed any)"
    fi
    
    # Always return success since uninstalled modules are not an error
    return 0
}

# =============================================================================
# FONCTION PRINCIPALE
# =============================================================================

# Display check summary
show_summary() {
    local status=0
    local total_checks=$#
    local passed_checks=0
    
    # Define check labels
    local check_labels=(
        "System dependencies"
        "Directory structure"
        "Permissions"
        "Configz installation"
        "Modules"
    )
    
    # Print summary header
    echo -e "\n${BOLD}=== CHECK SUMMARY ===${NC}\n"
    
    # Process each check
    for i in "${!check_labels[@]}"; do
        local check_status
        # Get the status from the corresponding parameter (1-based index)
        local param_index=$((i+1))
        check_status="${!param_index}"
        local label="${check_labels[$i]}"
        
        if [[ "$check_status" -eq 0 ]]; then
            echo -e "$((i+1)). $label: ${GREEN}[OK]${NC}"
            ((passed_checks++))
        else
            echo -e "$((i+1)). $label: ${RED}[FAIL]${NC}"
        fi
    done
    
    # Overall status
    echo -e "\n${BOLD}=== FINAL STATUS ===${NC}"
    
    if [[ $passed_checks -eq $total_checks ]]; then
        echo -e "${GREEN}SUCCESS:${NC} All health checks passed! (${GREEN}$passed_checks/$total_checks${NC})"
        status=0
    else
        local failed_checks=$((total_checks - passed_checks))
        echo -e "${RED}ERROR:${NC} Some issues were found (${RED}$failed_checks/$total_checks${NC} checks failed)\n"
        echo -e "${BOLD}Next steps:"
        echo "1. Review the error messages above"
        echo "2. Fix the reported issues"
        echo -e "3. Run ${BOLD}configz doctor${NC} again to verify the fixes"
        status=1
    fi
    
    echo
    return $status
}

# Main function
doctor_main() {
    # Ensure output is not buffered
    if [[ -n "${ZSH_VERSION:-}" ]]; then
        # Zsh specific settings
        setopt LOCAL_OPTIONS 2>/dev/null || true
        setopt LOCAL_TRAPS 2>/dev/null || true
        unsetopt MULTIOS 2>/dev/null || true
    else
        # Bash specific settings
        set -o pipefail 2>/dev/null || true
        # Disable exit on error temporarily to capture all check statuses
        set +e
    fi

    # Print header
    echo -e "${BOLD}=== CONFIGZ HEALTH CHECK ===${NC}"
    echo
    
    # Run checks
    echo -e "${BOLD}1. Checking system dependencies...${NC}"
    check_system_deps
    local system_deps_status=$?
    echo # Add extra newline
    
    echo -e "${BOLD}2. Checking directory structure...${NC}"
    check_directories
    local dirs_status=$?
    echo # Add extra newline
    
    echo -e "${BOLD}3. Checking permissions...${NC}"
    check_permissions
    local perms_status=$?
    echo # Add extra newline
    
    echo -e "${BOLD}4. Verifying Configz installation...${NC}"
    check_installation
    local install_status=$?
    echo # Add extra newline
    
    echo -e "${BOLD}5. Checking modules...${NC}"
    check_modules
    local modules_status=$?
    echo # Add extra newline
    
    # Show summary and get status
    show_summary $system_deps_status $dirs_status $perms_status $install_status $modules_status
    local summary_status=$?
    
    # Add final newline and flush output
    echo
    sync >/dev/null 2>&1 || true
    
    return $summary_status
}

# Run the main function
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    # Run doctor_main and capture its status
    if doctor_main "$@"; then
        exit 0
    else
        exit 1
    fi
fi
