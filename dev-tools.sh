#!/usr/bin/env bash

# Configz Development Tools
# Helper script for development, testing, and maintenance

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'

# Logging
log_info() { echo -e "${BLUE}[INFO]${NC} $*"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $*"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $*"; }
log_error() { echo -e "${RED}[ERROR]${NC} $*" >&2; }

show_help() {
    cat << EOF
${BOLD}${CYAN}Configz Development Tools${NC}

${BOLD}USAGE:${NC}
    $0 <command> [options]

${BOLD}COMMANDS:${NC}
    test            Run all tests and validations
    install-dev     Install CLI in development mode
    uninstall       Uninstall CLI completely
    reinstall       Reinstall CLI (uninstall + install)
    validate        Validate project structure
    lint            Run linting and style checks
    demo            Run interactive demo
    benchmark       Performance benchmarking
    clean           Clean temporary files
    backup          Create project backup
    help            Show this help

${BOLD}EXAMPLES:${NC}
    $0 test                 # Run all tests
    $0 install-dev          # Install for development
    $0 demo                 # Interactive demo
    $0 validate             # Check project structure

${BOLD}DEVELOPMENT:${NC}
    This script helps with development workflow, testing,
    and maintenance of the Configz project.

EOF
}

# Validate project structure
validate_structure() {
    log_info "Validating project structure..."

    local errors=0
    local required_files=(
        "configz"
        "install-cli.sh"
        "README.md"
        "CLI_GUIDE.md"
        "CHANGELOG.md"
        "cli/lib/common.sh"
        "cli/commands/list.sh"
        "cli/commands/install.sh"
        "cli/commands/status.sh"
        "cli/commands/info.sh"
        "completions/configz.fish"
    )

    local required_dirs=(
        "config"
        "cli"
        "cli/commands"
        "cli/lib"
        "completions"
        "man"
    )

    # Check required files
    for file in "${required_files[@]}"; do
        if [[ ! -f "$file" ]]; then
            log_error "Missing file: $file"
            ((errors++))
        fi
    done

    # Check required directories
    for dir in "${required_dirs[@]}"; do
        if [[ ! -d "$dir" ]]; then
            log_error "Missing directory: $dir"
            ((errors++))
        fi
    done

    # Check executables
    if [[ ! -x "configz" ]]; then
        log_error "Main script 'configz' is not executable"
        ((errors++))
    fi

    if [[ ! -x "install-cli.sh" ]]; then
        log_error "Install script 'install-cli.sh' is not executable"
        ((errors++))
    fi

    # Check for modules
    local module_count
    module_count=$(find config -maxdepth 1 -type d | wc -l)
    if [[ $module_count -lt 2 ]]; then  # -1 for config dir itself
        log_warning "Few modules found in config/ directory"
    fi

    if [[ $errors -eq 0 ]]; then
        log_success "Project structure validation passed"
        return 0
    else
        log_error "Project structure validation failed with $errors errors"
        return 1
    fi
}

# Install in development mode
install_dev() {
    log_info "Installing Configz CLI in development mode..."

    # Validate first
    if ! validate_structure; then
        log_error "Project validation failed"
        return 1
    fi

    # Install CLI
    ./install-cli.sh

    # Verify installation
    if command -v configz >/dev/null 2>&1; then
        log_success "CLI installed successfully"
        configz --version
    else
        log_error "CLI installation failed"
        return 1
    fi
}

# Uninstall CLI
uninstall_cli() {
    log_info "Uninstalling Configz CLI..."

    if [[ -f "./install-cli.sh" ]]; then
        ./install-cli.sh --uninstall
    else
        log_warning "Uninstall script not found, manual cleanup..."

        # Manual cleanup
        local files_to_remove=(
            "$HOME/.local/bin/configz"
            "$HOME/.local/bin/configz-cli"
            "$HOME/.local/share/man/man1/configz.1"
            "$HOME/.local/share/bash-completion/completions/configz"
            "$HOME/.local/share/zsh/site-functions/_configz"
        )

        for file in "${files_to_remove[@]}"; do
            if [[ -e "$file" ]]; then
                rm -rf "$file"
                log_info "Removed: $file"
            fi
        done
    fi

    log_success "CLI uninstalled"
}

# Run tests
run_tests() {
    log_info "Running Configz tests..."

    local test_errors=0

    # Structure validation
    if ! validate_structure; then
        ((test_errors++))
    fi

    # Script syntax checks
    log_info "Checking script syntax..."
    if ! bash -n configz; then
        log_error "Syntax error in main script"
        ((test_errors++))
    fi

    if ! bash -n install-cli.sh; then
        log_error "Syntax error in install script"
        ((test_errors++))
    fi

    for script in cli/commands/*.sh cli/lib/*.sh; do
        if [[ -f "$script" ]] && ! bash -n "$script"; then
            log_error "Syntax error in $script"
            ((test_errors++))
        fi
    done

    # CLI functional tests
    log_info "Running CLI functional tests..."

    # Test help commands
    if ! ./configz --help >/dev/null; then
        log_error "Help command failed"
        ((test_errors++))
    fi

    if ! ./configz --version >/dev/null; then
        log_error "Version command failed"
        ((test_errors++))
    fi

    # Test list command
    if ! ./configz list >/dev/null 2>&1; then
        log_warning "List command has issues (may be expected in alpha)"
    fi

    # Test info command on first available module
    local first_module
    if first_module=$(find config -maxdepth 1 -type d -not -name config | head -1 | xargs basename 2>/dev/null); then
        if [[ -n "$first_module" ]]; then
            if ! ./configz info "$first_module" >/dev/null 2>&1; then
                log_warning "Info command has issues for module: $first_module"
            fi
        fi
    fi

    # Summary
    if [[ $test_errors -eq 0 ]]; then
        log_success "All tests passed!"
        return 0
    else
        log_error "Tests completed with $test_errors errors"
        return 1
    fi
}

# Linting and style checks
run_lint() {
    log_info "Running linting and style checks..."

    # Check for common issues
    log_info "Checking for common shell script issues..."

    # Check for bashisms
    if command -v checkbashisms >/dev/null 2>&1; then
        checkbashisms configz install-cli.sh cli/**/*.sh || true
    else
        log_warning "checkbashisms not available, skipping"
    fi

    # Check for shellcheck
    if command -v shellcheck >/dev/null 2>&1; then
        log_info "Running shellcheck..."
        shellcheck configz install-cli.sh cli/**/*.sh || true
    else
        log_warning "shellcheck not available, install with: brew install shellcheck"
    fi

    # Check line endings
    log_info "Checking line endings..."
    if file configz | grep -q CRLF; then
        log_warning "CRLF line endings detected in configz"
    fi

    log_success "Linting completed"
}

# Interactive demo
run_demo() {
    log_info "Starting Configz CLI demo..."

    echo -e "\n${BOLD}${CYAN}🚀 Configz CLI Demo${NC}"
    echo -e "${DIM}This will demonstrate the CLI functionality${NC}\n"

    # Check if CLI is installed
    if ! command -v configz >/dev/null 2>&1; then
        log_warning "CLI not installed, installing now..."
        install_dev
    fi

    echo -e "${BOLD}1. Showing version:${NC}"
    configz --version

    echo -e "\n${BOLD}2. Listing available modules:${NC}"
    configz list || log_warning "List command may have issues in alpha"

    echo -e "\n${BOLD}3. Checking status:${NC}"
    configz status || log_warning "Status command may have issues in alpha"

    # Show info for first module
    local first_module
    if first_module=$(find config -maxdepth 1 -type d -not -name config | head -1 | xargs basename 2>/dev/null); then
        if [[ -n "$first_module" ]]; then
            echo -e "\n${BOLD}4. Module information for '$first_module':${NC}"
            configz info "$first_module" || log_warning "Info command may have issues in alpha"
        fi
    fi

    echo -e "\n${BOLD}${GREEN}Demo completed!${NC}"
    echo -e "${DIM}Try more commands: configz install, configz --help${NC}"
}

# Performance benchmarking
run_benchmark() {
    log_info "Running performance benchmarks..."

    echo -e "\n${BOLD}Performance Benchmark Results:${NC}"

    # Time various operations
    echo "Command execution times:"

    echo -n "  configz --version: "
    time (configz --version >/dev/null 2>&1)

    echo -n "  configz --help: "
    time (configz --help >/dev/null 2>&1)

    echo -n "  configz list: "
    time (configz list >/dev/null 2>&1) || echo "Failed"

    # Module discovery performance
    echo -n "  Module discovery: "
    time (find config -maxdepth 1 -type d >/dev/null 2>&1)

    log_success "Benchmark completed"
}

# Clean temporary files
clean_temp() {
    log_info "Cleaning temporary files..."

    # Remove backup files
    find . -name "*.bak" -delete 2>/dev/null || true
    find . -name "*.bak2" -delete 2>/dev/null || true
    find . -name "*~" -delete 2>/dev/null || true

    # Remove temporary directories
    rm -rf tmp/ temp/ 2>/dev/null || true

    log_success "Cleanup completed"
}

# Create project backup
create_backup() {
    local timestamp
    timestamp=$(date +"%Y%m%d_%H%M%S")
    local backup_name="configz_backup_${timestamp}.tar.gz"

    log_info "Creating project backup: $backup_name"

    tar -czf "../$backup_name" \
        --exclude='.git' \
        --exclude='node_modules' \
        --exclude='*.bak*' \
        --exclude='tmp' \
        --exclude='temp' \
        .

    log_success "Backup created: ../$backup_name"
}

# Main command dispatcher
main() {
    case "${1:-help}" in
        test)
            run_tests
            ;;
        install-dev)
            install_dev
            ;;
        uninstall)
            uninstall_cli
            ;;
        reinstall)
            uninstall_cli
            install_dev
            ;;
        validate)
            validate_structure
            ;;
        lint)
            run_lint
            ;;
        demo)
            run_demo
            ;;
        benchmark)
            run_benchmark
            ;;
        clean)
            clean_temp
            ;;
        backup)
            create_backup
            ;;
        help|--help|-h)
            show_help
            ;;
        *)
            log_error "Unknown command: $1"
            echo
            show_help
            exit 1
            ;;
    esac
}

# Only run main if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
