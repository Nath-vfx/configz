#!/usr/bin/env bash

# Configz CLI Global Installation Script
# Installs configz CLI system-wide for easy access

set -euo pipefail

# =============================================================================
# CONFIGURATION
# =============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROGRAM_NAME="configz"
VERSION="0.2.2-alpha"

# Installation paths
if [[ "$EUID" -eq 0 ]]; then
    # System-wide installation (root)
    INSTALL_DIR="/usr/local/bin"
    MAN_DIR="/usr/local/share/man/man1"
    COMPLETION_DIR="/usr/local/share/bash-completion/completions"
    ZSH_COMPLETION_DIR="/usr/local/share/zsh/site-functions"
else
    # User installation
    INSTALL_DIR="$HOME/.local/bin"
    MAN_DIR="$HOME/.local/share/man/man1"
    COMPLETION_DIR="$HOME/.local/share/bash-completion/completions"
    ZSH_COMPLETION_DIR="$HOME/.local/share/zsh/site-functions"
fi

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'

# =============================================================================
# UTILITY FUNCTIONS
# =============================================================================

log_info() {
    echo -e "${BLUE}[INFO]${NC} $*"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $*"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $*"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $*" >&2
}

command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# =============================================================================
# INSTALLATION FUNCTIONS
# =============================================================================

create_directories() {
    log_info "Creating installation directories..."

    for dir in "$INSTALL_DIR" "$MAN_DIR" "$COMPLETION_DIR" "$ZSH_COMPLETION_DIR"; do
        if [[ ! -d "$dir" ]]; then
            mkdir -p "$dir" || {
                log_error "Failed to create directory: $dir"
                return 1
            }
            log_info "Created directory: $dir"
        fi
    done
}

install_binary() {
    log_info "Installing configz binary..."

    local source_binary="$SCRIPT_DIR/configz"
    local target_binary="$INSTALL_DIR/configz"

    if [[ ! -f "$source_binary" ]]; then
        log_error "Source binary not found: $source_binary"
        return 1
    fi

    # Copy the main script
    cp "$source_binary" "$target_binary" || {
        log_error "Failed to copy binary to $target_binary"
        return 1
    }

    # Make it executable
    chmod +x "$target_binary" || {
        log_error "Failed to make binary executable"
        return 1
    }

    # Copy the CLI directory
    local target_cli_dir="$INSTALL_DIR/configz-cli"
    if [[ -d "$target_cli_dir" ]]; then
        rm -rf "$target_cli_dir"
    fi

    cp -r "$SCRIPT_DIR/cli" "$target_cli_dir" || {
        log_error "Failed to copy CLI directory"
        return 1
    }

    # Update paths in the installed binary
    sed -i.bak "s|CLI_DIR=\"\$SCRIPT_DIR/cli\"|CLI_DIR=\"$target_cli_dir\"|g" "$target_binary"
    sed -i.bak2 "s|CONFIG_SOURCE_DIR=\"\$SCRIPT_DIR/config\"|CONFIG_SOURCE_DIR=\"$SCRIPT_DIR/config\"|g" "$target_binary"
    rm -f "$target_binary.bak" "$target_binary.bak2"

    log_success "Binary installed to: $target_binary"
}

install_man_page() {
    log_info "Installing manual page..."

    local man_file="$MAN_DIR/configz.1"

    cat > "$man_file" << 'EOF'
.TH CONFIGZ 1 "2024" "configz 0.2.1-alpha" "User Commands"
.SH NAME
configz \- Modern configuration management CLI
.SH SYNOPSIS
.B configz
[\fIOPTIONS\fR] \fICOMMAND\fR [\fIARGS\fR...]
.SH DESCRIPTION
.B configz
is a modern, modular configuration management system that helps you organize and deploy your dotfiles and application configurations.
.SH COMMANDS
.TP
.BR install " [MODULE...]"
Install configuration modules
.TP
.BR list
List available modules
.TP
.BR status
Show installation status
.TP
.BR remove " [MODULE...]"
Remove installed modules
.TP
.BR backup " [MODULE...]"
Backup current configurations
.TP
.BR restore " [MODULE...]"
Restore from backup
.TP
.BR search " <QUERY>"
Search for modules
.TP
.BR update " [MODULE...]"
Update installed modules
.TP
.BR init " <NAME>"
Create a new module template
.TP
.BR info " <MODULE>"
Show detailed module information
.TP
.BR doctor
Check system health and dependencies
.SH OPTIONS
.TP
.BR \-h ", " \-\-help
Show help message
.TP
.BR \-V ", " \-\-version
Show version information
.TP
.BR \-v ", " \-\-verbose
Enable verbose output
.TP
.BR \-q ", " \-\-quiet
Suppress non-error output
.TP
.BR \-n ", " \-\-dry\-run
Show what would be done without executing
.TP
.BR \-\-no\-backup
Skip automatic backups
.TP
.BR \-f ", " \-\-force
Force operations without confirmation
.TP
.BR \-\-config\-dir " DIR"
Use custom config directory
.SH EXAMPLES
.TP
configz list
List all available modules
.TP
configz install fish starship
Install specific modules
.TP
configz status --installed
Show only installed modules
.TP
configz info nvim
Show detailed information about nvim module
.TP
configz backup --all
Backup all installed configurations
.SH FILES
.TP
.I ~/.config
Default target directory for configurations
.TP
.I ./config/
Source directory containing configuration modules
.TP
.I ./config/*/configz.toml
Optional module configuration files
.SH AUTHOR
Written by Your Name.
.SH "SEE ALSO"
.BR git (1),
.BR cp (1),
.BR find (1)
EOF

    log_success "Manual page installed to: $man_file"
}

install_bash_completion() {
    log_info "Installing bash completion..."

    local completion_file="$COMPLETION_DIR/configz"

    cat > "$completion_file" << 'EOF'
#!/usr/bin/env bash

# Configz bash completion

_configz() {
    local cur prev opts commands
    COMPREPLY=()
    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]}"

    commands="install list status remove backup restore search update init info doctor"

    # Global options
    opts="--help --version --verbose --quiet --dry-run --no-backup --force --config-dir"

    # Complete commands
    if [[ ${COMP_CWORD} -eq 1 ]]; then
        COMPREPLY=($(compgen -W "${commands}" -- ${cur}))
        return 0
    fi

    # Complete based on command
    local command="${COMP_WORDS[1]}"
    case "${command}" in
        install|status|remove|backup|restore|info)
            # Complete with available modules
            if command -v configz >/dev/null 2>&1; then
                local modules
                modules=$(configz list --json 2>/dev/null | grep '"id"' | cut -d'"' -f4 2>/dev/null || echo "")
                COMPREPLY=($(compgen -W "${modules}" -- ${cur}))
            fi
            ;;
        list)
            local list_opts="--all --installed --uninstalled --long --json --no-color"
            COMPREPLY=($(compgen -W "${list_opts}" -- ${cur}))
            ;;
        *)
            COMPREPLY=($(compgen -W "${opts}" -- ${cur}))
            ;;
    esac
}

complete -F _configz configz
EOF

    log_success "Bash completion installed to: $completion_file"
}

install_zsh_completion() {
    log_info "Installing zsh completion..."

    local completion_file="$ZSH_COMPLETION_DIR/_configz"

    cat > "$completion_file" << 'EOF'
#compdef configz

# Configz zsh completion

_configz() {
    local context state line
    typeset -A opt_args

    _arguments -C \
        '(- *)'{-h,--help}'[Show help message]' \
        '(- *)'{-V,--version}'[Show version information]' \
        '(-v --verbose)'{-v,--verbose}'[Enable verbose output]' \
        '(-q --quiet)'{-q,--quiet}'[Suppress non-error output]' \
        '(-n --dry-run)'{-n,--dry-run}'[Show what would be done without executing]' \
        '--no-backup[Skip automatic backups]' \
        '(-f --force)'{-f,--force}'[Force operations without confirmation]' \
        '--config-dir[Use custom config directory]:directory:_directories' \
        '1: :_configz_commands' \
        '*:: :_configz_command_args'
}

_configz_commands() {
    local commands=(
        'install:Install configuration modules'
        'list:List available modules'
        'status:Show installation status'
        'remove:Remove installed modules'
        'backup:Backup current configurations'
        'restore:Restore from backup'
        'search:Search for modules'
        'update:Update installed modules'
        'init:Create a new module template'
        'info:Show detailed module information'
        'doctor:Check system health and dependencies'
    )
    _describe 'commands' commands
}

_configz_command_args() {
    case $words[1] in
        install|status|remove|backup|restore|info)
            _configz_modules
            ;;
        list)
            _arguments \
                '(-a --all)'{-a,--all}'[Show all modules]' \
                '(-i --installed)'{-i,--installed}'[Show only installed modules]' \
                '(-u --uninstalled)'{-u,--uninstalled}'[Show only uninstalled modules]' \
                '(-l --long)'{-l,--long}'[Show detailed information]' \
                '--json[Output in JSON format]' \
                '--no-color[Disable colored output]'
            ;;
    esac
}

_configz_modules() {
    local modules
    if (( $+commands[configz] )); then
        modules=(${(f)"$(configz list --json 2>/dev/null | grep '"id"' | cut -d'"' -f4 2>/dev/null)"})
        _describe 'modules' modules
    fi
}

_configz "$@"
EOF

    log_success "Zsh completion installed to: $completion_file"
}

update_path() {
    local shell_rc=""
    local shell_name=""

    # Detect shell and appropriate RC file
    if [[ -n "${BASH_VERSION:-}" ]]; then
        shell_name="bash"
        if [[ -f "$HOME/.bashrc" ]]; then
            shell_rc="$HOME/.bashrc"
        elif [[ -f "$HOME/.bash_profile" ]]; then
            shell_rc="$HOME/.bash_profile"
        fi
    elif [[ -n "${ZSH_VERSION:-}" ]]; then
        shell_name="zsh"
        shell_rc="$HOME/.zshrc"
    elif [[ "$SHELL" == */fish ]]; then
        shell_name="fish"
        shell_rc="$HOME/.config/fish/config.fish"
    fi

    # Add to PATH if not system-wide installation
    if [[ "$EUID" -ne 0 ]] && [[ -n "$shell_rc" ]]; then
        if [[ ! -d "$(dirname "$INSTALL_DIR")" ]] || ! echo "$PATH" | grep -q "$INSTALL_DIR"; then
            log_info "Adding $INSTALL_DIR to PATH in $shell_rc"

            if [[ "$shell_name" == "fish" ]]; then
                echo "set -gx PATH $INSTALL_DIR \$PATH" >> "$shell_rc"
            else
                echo "export PATH=\"$INSTALL_DIR:\$PATH\"" >> "$shell_rc"
            fi

            log_warning "Please restart your shell or run: source $shell_rc"
        fi
    fi
}

verify_installation() {
    log_info "Verifying installation..."

    if [[ -x "$INSTALL_DIR/configz" ]]; then
        log_success "Binary is executable"

        # Test basic functionality
        if "$INSTALL_DIR/configz" --version >/dev/null 2>&1; then
            log_success "Binary runs correctly"
        else
            log_warning "Binary installed but may not work correctly"
        fi
    else
        log_error "Binary not found or not executable"
        return 1
    fi

    # Check if it's in PATH
    if [[ "$EUID" -eq 0 ]] || echo "$PATH" | grep -q "$INSTALL_DIR"; then
        log_success "configz is in PATH"
    else
        log_warning "configz may not be in PATH - restart your shell"
    fi
}

# =============================================================================
# MAIN INSTALLATION
# =============================================================================

show_help() {
    cat << EOF
Configz CLI Installation Script

USAGE:
    $0 [OPTIONS]

OPTIONS:
    -h, --help      Show this help message
    --uninstall     Uninstall configz
    --user          Force user installation (default for non-root)
    --system        Force system installation (requires root)

DESCRIPTION:
    Installs configz CLI globally for easy access from anywhere.

    User installation (default for non-root):
        Binary: ~/.local/bin/configz
        Man page: ~/.local/share/man/man1/configz.1

    System installation (root only):
        Binary: /usr/local/bin/configz
        Man page: /usr/local/share/man/man1/configz.1

EOF
}

uninstall() {
    log_info "Uninstalling configz..."

    local files_to_remove=(
        "$INSTALL_DIR/configz"
        "$INSTALL_DIR/configz-cli"
        "$MAN_DIR/configz.1"
        "$COMPLETION_DIR/configz"
        "$ZSH_COMPLETION_DIR/_configz"
    )

    for file in "${files_to_remove[@]}"; do
        if [[ -e "$file" ]]; then
            rm -rf "$file"
            log_info "Removed: $file"
        fi
    done

    log_success "Configz uninstalled successfully"
}

main() {
    local uninstall_mode=0
    local force_user=0
    local force_system=0

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_help
                exit 0
                ;;
            --uninstall)
                uninstall_mode=1
                shift
                ;;
            --user)
                force_user=1
                shift
                ;;
            --system)
                force_system=1
                shift
                ;;
            *)
                log_error "Unknown option: $1"
                show_help
                exit 1
                ;;
        esac
    done

    # Adjust installation paths based on flags
    if [[ $force_system -eq 1 ]]; then
        if [[ "$EUID" -ne 0 ]]; then
            log_error "System installation requires root privileges"
            exit 1
        fi
        INSTALL_DIR="/usr/local/bin"
        MAN_DIR="/usr/local/share/man/man1"
        COMPLETION_DIR="/usr/local/share/bash-completion/completions"
        ZSH_COMPLETION_DIR="/usr/local/share/zsh/site-functions"
    elif [[ $force_user -eq 1 ]]; then
        INSTALL_DIR="$HOME/.local/bin"
        MAN_DIR="$HOME/.local/share/man/man1"
        COMPLETION_DIR="$HOME/.local/share/bash-completion/completions"
        ZSH_COMPLETION_DIR="$HOME/.local/share/zsh/site-functions"
    fi

    # Show installation info
    echo -e "${BOLD}${CYAN}Configz CLI Installation${NC}"
    echo -e "${DIM}Version: $VERSION${NC}"
    echo

    if [[ $uninstall_mode -eq 1 ]]; then
        uninstall
        return 0
    fi

    log_info "Installation type: $([ "$EUID" -eq 0 ] && echo "system-wide" || echo "user")"
    log_info "Install directory: $INSTALL_DIR"

    # Run installation steps
    create_directories || exit 1
    install_binary || exit 1
    install_man_page || exit 1
    install_bash_completion || exit 1
    install_zsh_completion || exit 1
    update_path
    verify_installation || exit 1

    echo
    log_success "Configz CLI installed successfully!"
    echo
    echo -e "${BOLD}Next steps:${NC}"
    echo "1. Restart your shell or run: source ~/.bashrc (or ~/.zshrc)"
    echo "2. Run: configz --help"
    echo "3. Run: configz list"
    echo
    echo -e "${DIM}To uninstall: $0 --uninstall${NC}"
}

# Only run main if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
