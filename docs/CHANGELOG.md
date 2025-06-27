# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.4.0-alpha] - 2025-06-27

### ✨ Major Changes

#### Simplified Init Command
- **Streamlined workflow**: The `init` command has been completely refactored for simplicity and reliability
- **Removed complexity**: Advanced options have been temporarily removed to ensure a stable core
- **Improved validation**: Better module name validation and error messages
- **Cleaner codebase**: Major code cleanup and restructuring

### 🔧 Enhanced
- **Documentation**: Complete overhaul of README and documentation
- **Error handling**: More robust error handling and user feedback
- **Code quality**: Improved code organization and maintainability

### 🚀 New Features
- **Basic module creation**: Simple and reliable module initialization
- **Config file generation**: Automatic creation of `configz.toml` with sensible defaults
- **Module structure**: Standardized module directory structure

### 🔒 Security
- **Safer operations**: No destructive actions without confirmation
- **Input validation**: Strict validation of all user inputs

### 📦 Dependencies
- **Minimal dependencies**: Reduced external dependencies for better reliability

### 🐛 Bug Fixes
- Fixed various edge cases in module initialization
- Resolved issues with path handling
- Improved error messages for better debugging

### 📝 Documentation
- Updated all documentation to reflect current features
- Added clear examples for all commands
- Improved help messages and user guidance


## [0.3.0-alpha] - 2025-01-21

### ✨ Major Features Added

#### Symlinks by Default with --no-symlink Flag
- **Symlinks as default**: Modules are now installed as symlinks by default for real-time configuration updates
- **--no-symlink flag**: Added option to use legacy copy mode when needed
- **Intelligent removal**: Automatic detection and proper handling of both symlinked and copied modules
- **Installation type display**: Status command now shows 🔗 for symlinks and 📁 for copied directories

#### Hidden Directory Filtering with --show-hidden Flag
- **Hidden directories filtered**: Directories starting with `.` are hidden by default for security
- **--show-hidden flag**: Added option to show hidden directories with security warnings
- **Directory-only discovery**: Enhanced module discovery to only process directories (never files)
- **Empty directory filtering**: Directories without content are automatically filtered out

#### Hidden Module Installation Protection with --install-hidden Flag
- **Hidden module protection**: Installation of hidden modules requires explicit `--install-hidden` flag
- **Double confirmation**: Hidden module installation requires user confirmation with typed phrase
- **Security warnings**: Clear warnings about risks of installing hidden configurations
- **Selective installation**: `configz install --all` excludes hidden modules by default

#### Dependency Checking in Installation Script
- **Pre-installation checks**: install-cli.sh now verifies all required dependencies before installation
- **Required dependencies**: Essential tools (find, cp, ln, etc.) must be present
- **YQ as required**: yq is now a required dependency (moved from optional) for configz.toml parsing
- **Optional dependencies**: jq and git remain optional with clear explanations of their benefits
- **Skip option**: --skip-deps flag allows bypassing checks in emergency situations

### 🔧 Enhanced
- **Fish autocompletion**: Updated with all new flags and options
- **Error messages**: Improved clarity and helpfulness of error messages
- **User experience**: Better guidance for security-sensitive operations
- **Installation robustness**: More reliable installation process with dependency validation

### 🔒 Security
- **Hidden content protection**: Multiple layers of protection against accidental installation of sensitive configurations
- **User awareness**: Clear warnings and confirmations for potentially dangerous operations
- **Selective visibility**: Hidden directories and modules require explicit user action to access

## [0.2.2-alpha] - 2025-06-22

### Added
- **Option `--modules-dir`**: Personnalisation du chemin des modules
- **Nouvelle structure de documentation**: guides utilisateur et développeur, exemples, guides avancés (3000+ lignes)
- **README**: Mise à jour pour la version 0.2.2-alpha et la nouvelle structure
- **Support complet du dossier `~/.config/configz/modules`** (par défaut, plus de dossier config/ dans le repo)
- **Compatibilité ascendante**: Migration automatique possible via `--modules-dir`
- **.gitignore**: Nettoyage et simplification

### Changed
- **Suppression de tous les exemples/configs du repo**: Les modules sont désormais personnels et hors repo
- **Documentation**: Tout est rangé dans `docs/` avec navigation claire
- **README**: Ajout de la version, instructions de migration, liens vers la doc
- **Installateur**: Seul `install-cli.sh` reste, suppression de l'ancien installateur interactif

### Removed
- **Dossiers et fichiers obsolètes**: config/, config-examples/, release-*, scripts de dev, anciens guides, artéfacts de build
- **Références à l'ancien système de modules dans le repo**

### Fixed
- **Aucune régression**: Toutes les commandes principales testées et validées
- **Compatibilité**: Les modules existants sont préservés lors de la migration

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

- **0.3.0-alpha**: Modern CLI interface (current)
- **0.2.0-alpha**: Modern CLI interface (previous)
- **0.1.0**: Interactive installation system (stable)

## Migration Notes

### From 0.2.x to 0.3.0-alpha

Version 0.3.0-alpha introduces major security and usability improvements:
- Symlinks are now the default installation method
- Hidden directories are filtered by default for security
- Enhanced dependency checking in installation script
- yq is now a required dependency

### From 0.1.0 to 0.2.0-alpha

The original interactive installer (`./install.sh`) remains fully functional and stable. The new CLI interface (`configz`) provides additional functionality and can be used alongside the original installer.

To use the new CLI:
1. Install globally: `./install-cli.sh`
2. Use modern commands: `configz list`, `configz install`, etc.
3. Keep using `./install.sh` for the original interface if preferred

Both interfaces work with the same module structure and configuration files.