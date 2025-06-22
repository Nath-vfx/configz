# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.2.1-alpha] - 2024-12-21

### Added
- **Complete `remove` command implementation** - Fully functional module removal
- **Backup management** - Automatic backups before removal with optional cleanup
- **Multi-module removal** - Remove multiple modules in a single command
- **Dry-run support** - Preview removal operations with `--dry-run`
- **Force mode** - Skip confirmations with `--force`
- **Registry updates** - Track removal operations in registry.json
- **Comprehensive error handling** - Robust validation and error reporting
- **Backup cleanup** - Optional removal of existing backups with `--clean`
- **Detailed reporting** - Clear summaries of removal operations
- **Command help** - Complete documentation for remove command

### Enhanced
- **Remove command** - From stub to full implementation
- **CLI stability** - Remove is now production-ready
- **User experience** - Clear feedback and confirmation flows
- **Safety features** - Multiple safeguards against accidental removal

### Fixed
- **Remove functionality** - No longer a stub, fully operational
- **Error handling** - Proper exit codes and error messages
- **Registry tracking** - Module removal properly recorded

### Technical
- **Backup system** - Integrated with existing backup infrastructure
- **Registry management** - JSON updates for removal tracking
- **Command validation** - Robust module existence and installation checks
- **Multi-module support** - Efficient batch processing

## [0.2.0-alpha] - 2024-12-21

### Added
- **New CLI Interface** - Complete rewrite as a modern command-line tool
- `configz list` - List available modules with filtering options
- `configz install` - Install modules with interactive selection
- `configz status` - Show installation status with detailed information
- `configz info` - Display comprehensive module information
- `configz remove` - Remove installed modules (command structure ready)
- `configz backup` - Backup configurations (command structure ready)
- `configz restore` - Restore from backups (command structure ready)
- Global installation script (`install-cli.sh`) for system-wide access
- Auto-completion support for Bash, Zsh, and Fish shells
- Manual page (`man configz`) for documentation
- JSON output format for scripting and automation
- Comprehensive error handling and logging
- Dry-run mode for safe previewing of operations
- Verbose and quiet modes for different output levels
- Force mode for non-interactive operations
- Custom config directory support

### Enhanced
- Modular CLI architecture with separate command files
- Improved metadata parsing with better TOML support
- Robust backup system with timestamp-based naming
- Enhanced module discovery with better error handling
- Professional help system with command-specific documentation

### Technical
- New `cli/` directory structure for command organization
- Common library (`cli/lib/common.sh`) for shared functionality
- Safe error handling wrapper functions
- Improved path resolution and validation
- Better dependency checking for system and module requirements

### Documentation
- Complete CLI usage guide (`CLI_GUIDE.md`)
- Updated README with CLI information
- Comprehensive help text for all commands
- Examples and troubleshooting sections

## [0.1.0] - 2024-12-20

### Added
- Initial release with interactive installation interface
- Automatic module discovery from `config/` directory
- Two-phase installation process (selection + installation)
- Keyboard navigation with arrow keys and spacebar selection
- Automatic backup system with timestamps
- Support for `configz.toml` configuration files
- Module metadata support (name, description, icon, version, author)
- Dependency checking (system packages and modules)
- Post-installation notes and instructions
- Colored terminal interface with icons
- Preview mode for installation planning
- Batch installation with progress tracking

### Features
- Auto-discovery of configuration modules
- Interactive checkbox interface for module selection
- Automatic backups before installation
- TOML-based module configuration
- Cross-platform compatibility (macOS/Linux)
- Zero-configuration setup for basic modules
- Extensible module system

### Supported Modules
- Fish Shell configuration
- Ghostty Terminal configuration
- Starship Prompt configuration
- Neovim configuration
- Custom module support

---

## Version History

- **0.2.0-alpha**: Modern CLI interface (current)
- **0.1.0**: Interactive installation system (stable)

## Migration Notes

### From 0.1.0 to 0.2.0-alpha

The original interactive installer (`./install.sh`) remains fully functional and stable. The new CLI interface (`configz`) provides additional functionality and can be used alongside the original installer.

To use the new CLI:
1. Install globally: `./install-cli.sh`
2. Use modern commands: `configz list`, `configz install`, etc.
3. Keep using `./install.sh` for the original interface if preferred

Both interfaces work with the same module structure and configuration files.