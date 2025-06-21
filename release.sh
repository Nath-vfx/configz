#!/usr/bin/env bash

# Configz Release Script
# Automates the release process for new versions

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Current version
CURRENT_VERSION="0.2.1-alpha"
RELEASE_DATE=$(date +"%Y-%m-%d")

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
${BOLD}${CYAN}Configz Release Script${NC}

${BOLD}USAGE:${NC}
    $0 [OPTIONS] [VERSION]

${BOLD}OPTIONS:${NC}
    -h, --help          Show this help message
    -d, --dry-run       Show what would be done without executing
    -f, --force         Skip confirmations
    --no-git           Skip git operations
    --no-install       Skip installation test
    --no-validate      Skip validation checks

${BOLD}ARGUMENTS:${NC}
    VERSION             Version to release (default: $CURRENT_VERSION)

${BOLD}EXAMPLES:${NC}
    $0                          # Release current version
    $0 0.2.2-alpha             # Release specific version
    $0 --dry-run               # Preview release process
    $0 --force 0.3.0-alpha     # Force release without confirmations

${BOLD}RELEASE PROCESS:${NC}
    1. Validate project structure and tests
    2. Update version numbers in all files
    3. Run comprehensive tests
    4. Create installation package
    5. Generate release artifacts
    6. Create git tag (if --no-git not specified)
    7. Display release summary

EOF
}

# Validate environment
validate_environment() {
    log_info "Validating environment..."

    # Check required tools
    local missing_tools=()

    if ! command -v git >/dev/null 2>&1; then
        missing_tools+=("git")
    fi

    if ! command -v jq >/dev/null 2>&1; then
        missing_tools+=("jq")
    fi

    if [[ ${#missing_tools[@]} -gt 0 ]]; then
        log_error "Missing required tools: ${missing_tools[*]}"
        return 1
    fi

    # Check project structure
    local required_files=(
        "configz"
        "install-cli.sh"
        "README.md"
        "CHANGELOG.md"
        "cli/lib/common.sh"
    )

    for file in "${required_files[@]}"; do
        if [[ ! -f "$file" ]]; then
            log_error "Missing required file: $file"
            return 1
        fi
    done

    log_success "Environment validation passed"
}

# Update version numbers
update_version() {
    local version="$1"

    log_info "Updating version to $version..."

    # Files to update
    local version_files=(
        "configz"
        "install-cli.sh"
        "CLI_GUIDE.md"
        "ALPHA_STATUS.md"
    )

    for file in "${version_files[@]}"; do
        if [[ -f "$file" ]]; then
            if [[ $DRY_RUN -eq 1 ]]; then
                log_info "Would update version in: $file"
            else
                # Update version in file
                if [[ "$file" == "configz" || "$file" == "install-cli.sh" ]]; then
                    sed -i.bak "s/VERSION=\"[^\"]*\"/VERSION=\"$version\"/g" "$file"
                    sed -i.bak2 "s/Version: [0-9][^\"]*\"/Version: $version\"/g" "$file"
                else
                    sed -i.bak "s/v[0-9]\+\.[0-9]\+\.[0-9]\+[^\"]*alpha/v$version/g" "$file"
                fi

                # Clean backup files
                rm -f "$file.bak" "$file.bak2" 2>/dev/null || true

                log_info "Updated version in: $file"
            fi
        fi
    done

    log_success "Version updated to $version"
}

# Run tests
run_tests() {
    log_info "Running comprehensive tests..."

    if [[ $DRY_RUN -eq 1 ]]; then
        log_info "Would run: ./dev-tools.sh test"
        return 0
    fi

    if [[ -f "dev-tools.sh" ]]; then
        if ./dev-tools.sh test; then
            log_success "All tests passed"
        else
            log_error "Tests failed"
            return 1
        fi
    else
        log_warning "dev-tools.sh not found, skipping automated tests"
    fi
}

# Test installation
test_installation() {
    log_info "Testing installation..."

    if [[ $DRY_RUN -eq 1 ]]; then
        log_info "Would test CLI installation"
        return 0
    fi

    # Install CLI
    if ./install-cli.sh >/dev/null 2>&1; then
        log_success "Installation test passed"

        # Test basic functionality
        if configz --version >/dev/null 2>&1; then
            log_success "CLI functionality test passed"
        else
            log_error "CLI functionality test failed"
            return 1
        fi
    else
        log_error "Installation test failed"
        return 1
    fi
}

# Create release artifacts
create_artifacts() {
    local version="$1"

    log_info "Creating release artifacts..."

    local release_dir="release-$version"

    if [[ $DRY_RUN -eq 1 ]]; then
        log_info "Would create release directory: $release_dir"
        log_info "Would create release package: configz-$version.tar.gz"
        return 0
    fi

    # Create release directory
    rm -rf "$release_dir"
    mkdir -p "$release_dir"

    # Copy essential files
    local release_files=(
        "configz"
        "install-cli.sh"
        "README.md"
        "CHANGELOG.md"
        "CLI_GUIDE.md"
        "ALPHA_STATUS.md"
        "RELEASE_NOTES_v$version.md"
        "cli/"
        "config/"
        "completions/"
        "man/"
        "config.toml.template"
    )

    for item in "${release_files[@]}"; do
        if [[ -e "$item" ]]; then
            cp -r "$item" "$release_dir/"
            log_info "Added to release: $item"
        fi
    done

    # Create release package
    tar -czf "configz-$version.tar.gz" "$release_dir"
    log_success "Created release package: configz-$version.tar.gz"

    # Create checksums
    if command -v shasum >/dev/null 2>&1; then
        shasum -a 256 "configz-$version.tar.gz" > "configz-$version.sha256"
        log_success "Created checksums: configz-$version.sha256"
    fi
}

# Create git tag
create_git_tag() {
    local version="$1"

    if [[ $NO_GIT -eq 1 ]]; then
        log_info "Skipping git operations (--no-git specified)"
        return 0
    fi

    log_info "Creating git tag..."

    if [[ $DRY_RUN -eq 1 ]]; then
        log_info "Would create git tag: v$version"
        log_info "Would commit version changes"
        return 0
    fi

    # Check if we're in a git repository
    if ! git rev-parse --git-dir >/dev/null 2>&1; then
        log_warning "Not in a git repository, skipping git operations"
        return 0
    fi

    # Commit version changes
    git add -A
    if git commit -m "Release v$version

- Update version numbers
- Complete remove command implementation
- Enhanced CLI stability and functionality
" >/dev/null 2>&1; then
        log_success "Committed version changes"
    else
        log_info "No changes to commit"
    fi

    # Create tag
    if git tag -a "v$version" -m "Release v$version

Major improvements:
- Complete remove command implementation
- Enhanced error handling and stability
- Improved user experience
- Comprehensive testing and validation

See RELEASE_NOTES_v$version.md for full details.
"; then
        log_success "Created git tag: v$version"
    else
        log_warning "Failed to create git tag (tag may already exist)"
    fi
}

# Display release summary
show_summary() {
    local version="$1"

    echo
    echo -e "${BOLD}${GREEN}🎉 Release v$version Completed Successfully! 🎉${NC}"
    echo -e "${DIM}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo
    echo -e "${BOLD}📦 Release Artifacts:${NC}"

    if [[ -f "configz-$version.tar.gz" ]]; then
        echo -e "  ✅ configz-$version.tar.gz"
    fi

    if [[ -f "configz-$version.sha256" ]]; then
        echo -e "  ✅ configz-$version.sha256"
    fi

    if [[ -d "release-$version" ]]; then
        echo -e "  ✅ release-$version/ directory"
    fi

    echo
    echo -e "${BOLD}🚀 What's New:${NC}"
    echo -e "  ✨ Complete remove command implementation"
    echo -e "  🛡️ Enhanced safety features with backups"
    echo -e "  🎯 Improved error handling and validation"
    echo -e "  📊 Better user experience and reporting"

    echo
    echo -e "${BOLD}📋 Next Steps:${NC}"
    echo -e "  1. Test the release: ${CYAN}./release-$version/install-cli.sh${NC}"
    echo -e "  2. Verify functionality: ${CYAN}configz --version${NC}"
    echo -e "  3. Share the release: ${CYAN}configz-$version.tar.gz${NC}"

    if [[ $NO_GIT -eq 0 ]]; then
        echo -e "  4. Push git tag: ${CYAN}git push origin v$version${NC}"
    fi

    echo
    echo -e "${BOLD}📖 Documentation:${NC}"
    echo -e "  • Release Notes: ${DIM}RELEASE_NOTES_v$version.md${NC}"
    echo -e "  • User Guide: ${DIM}CLI_GUIDE.md${NC}"
    echo -e "  • Alpha Status: ${DIM}ALPHA_STATUS.md${NC}"

    echo
    echo -e "${DIM}Release created on: $RELEASE_DATE${NC}"
}

# Main release function
main() {
    local version="$CURRENT_VERSION"
    local dry_run=0
    local force=0
    local no_git=0
    local no_install=0
    local no_validate=0

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_help
                exit 0
                ;;
            -d|--dry-run)
                dry_run=1
                shift
                ;;
            -f|--force)
                force=1
                shift
                ;;
            --no-git)
                no_git=1
                shift
                ;;
            --no-install)
                no_install=1
                shift
                ;;
            --no-validate)
                no_validate=1
                shift
                ;;
            -*)
                log_error "Unknown option: $1"
                show_help
                exit 1
                ;;
            *)
                version="$1"
                shift
                ;;
        esac
    done

    # Export flags for use in functions
    export DRY_RUN=$dry_run
    export FORCE=$force
    export NO_GIT=$no_git
    export NO_INSTALL=$no_install
    export NO_VALIDATE=$no_validate

    # Header
    echo -e "${BOLD}${CYAN}🚀 Configz Release Process v$version${NC}"
    if [[ $dry_run -eq 1 ]]; then
        echo -e "${YELLOW}[DRY RUN MODE]${NC}"
    fi
    echo

    # Validation
    if [[ $no_validate -eq 0 ]]; then
        validate_environment || exit 1
    fi

    # Confirmation
    if [[ $force -eq 0 && $dry_run -eq 0 ]]; then
        echo -e "${BOLD}Release Summary:${NC}"
        echo -e "  Version: ${GREEN}$version${NC}"
        echo -e "  Date: ${DIM}$RELEASE_DATE${NC}"
        echo
        read -p "Proceed with release? [y/N] " -r
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            log_info "Release cancelled"
            exit 0
        fi
        echo
    fi

    # Release steps
    log_info "Starting release process for v$version..."
    echo

    # Step 1: Update version
    update_version "$version"

    # Step 2: Run tests
    run_tests || exit 1

    # Step 3: Test installation
    if [[ $no_install -eq 0 ]]; then
        test_installation || exit 1
    fi

    # Step 4: Create artifacts
    create_artifacts "$version"

    # Step 5: Git operations
    create_git_tag "$version"

    # Step 6: Summary
    show_summary "$version"
}

# Only run main if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
