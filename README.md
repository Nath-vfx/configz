# Configz - Modern Configuration Management CLI

**Version : 0.4.0-alpha**

A modern, modular configuration management system for your dotfiles and application configurations.

> **Note:** This is an alpha version. The CLI interface and features are still evolving.

## 🚀 Quick Start

### Installation

```bash
# Clone the repository
git clone https://github.com/Nath-vfx/configz.git
cd configz

# Install the CLI globally
./install-cli.sh

# Start using it
configz --version   # -> must show 0.4.0-alpha
configz list
```

### First Time Setup

```bash
# Initialize the configz directory structure (first time only)
configz init my-app

# List available modules (will show your new module)
configz list
```

## 🚨 Breaking Changes in v0.4.0

- Simplified `init` command with a more focused feature set
- Removed some advanced options from `init` that will be reimplemented in future versions
- Improved error handling and validation
- More consistent command output formatting

## ✨ Features

- 🎯 **Modern CLI** with intuitive commands and colorful output
- 📦 **Auto-discovery** - Automatically detects modules in your modules directory
- ⚙️ **Simple configuration** - Basic `configz.toml` file generation
- 🔒 **Safe operations** - No destructive actions without confirmation
- 🎨 **Rich output** with colors and clear feedback
- 🔧 **Extensible** - Add a directory = new module available
- ⚡ **Fast and lightweight** - Minimal dependencies, fast execution

## 📁 Default Structure

```
~/.config/configz/
├── modules/                   # Your configuration modules
│   ├── fish/                  # Fish shell configuration
│   │   ├── config.fish        # Configuration files
│   │   └── configz.toml       # (optional) Module metadata
│   ├── nvim/                  # Neovim configuration
│   │   ├── init.lua           # Configuration files
│   │   └── configz.toml       # Module settings
│   └── starship/              # Starship prompt
│       ├── starship.toml      # Configuration files
│       └── configz.toml       # Module metadata
├── backups/                   # Automatic backups
└── config.toml               # Global configz settings
```

## 🎮 Basic Usage

### Initialize a New Module
```bash
# Create a new module with default configuration
configz init my-module

# The module will be created in: ~/.config/configz/modules/my-module
# A basic configz.toml file will be generated automatically
```

### List Modules
```bash
configz list                   # List all available modules
configz list --installed       # Show only installed modules
```

### Install Modules
```bash
configz install my-module      # Install a single module
configz install --all          # Install all available modules
```

### Get Module Information
```bash
configz info my-module        # Show module details
configz status                # Show installation status
```

## 📖 Creating Modules

### Module Structure

When you create a new module with `configz init <name>`, the following structure is created:

```
~/.config/configz/modules/
└── <module-name>/
    └── configz.toml     # Module configuration
    └── ...               # Your configuration files
```

### The configz.toml File

A basic `configz.toml` is automatically created with these default values:

```toml
[module]
name = "module-name"
description = "Configuration for module-name"
icon = "📦"
version = "0.1.0"
author = "your-username"

[installation]
type = "symlink"  # or "copy"

[paths]
target = "module-name"
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
```

### Simple Module (Auto-detected)
```bash
# Create directory and add files
mkdir -p ~/.config/configz/modules/myapp
echo "setting=value" > ~/.config/configz/modules/myapp/config.conf

# Module is now available
configz list
```

### Advanced Module (With Metadata)
```bash
# Create module directory
mkdir -p ~/.config/configz/modules/myapp

# Create configuration files
echo "setting=value" > ~/.config/configz/modules/myapp/config.conf

# Create metadata file
cat > ~/.config/configz/modules/myapp/configz.toml << 'EOF'
[module]
name = "My Application"
description = "Custom configuration for my app"
icon = "🚀"
version = "1.0.0"
author = "Your Name"

[installation]
type = "copy"  # or "symlink"

[paths]
target = "myapp"  # Will install to ~/.config/myapp/
sources = ["config.conf"]

[dependencies]
system = ["myapp"]  # Required system packages
modules = []        # Required other configz modules

[post_install]
notes = [
    "Don't forget to restart myapp",
    "Check the configuration with: myapp --check-config"
]

[backup]
strategy = "auto"  # "auto", "manual", or "none"
files = ["config.conf"]
EOF
```

## 🔧 Advanced Features

### Environment Variables
```bash
export CONFIGZ_MODULES_DIR="~/my-configs"  # Custom modules directory
export CONFIGZ_CONFIG_DIR="~/my-dotfiles"  # Custom target directory
```

### Global Configuration
Create `~/.config/configz/config.toml`:
```toml
[default]
modules_dir = "~/.config/configz/modules"
config_dir = "~/.config"
backup_strategy = "auto"

[install]
create_backups = true
force_overwrite = false
dry_run = false

[display]
show_icons = true
colored_output = true
verbose = false
```

## 📚 Commands Reference

| Command | Description |
|---------|-------------|
| `list` | List available modules |
| `install` | Install configuration modules |
| `remove` | Remove installed modules |
| `status` | Show installation status |
| `info` | Show detailed module information |
| `backup` | Create backups of configurations |
| `restore` | Restore from backups |
| `init` | Create new module template |
| `doctor` | Check system health |
| `migrate` | Migrate from old structure |

## 🎯 Examples

```bash
# Basic workflow
configz list                           # See what's available
configz info fish                      # Get details about fish module
configz install fish                   # Install fish configuration
configz status                         # Check what's installed

# Advanced usage
configz --modules-dir ~/work-configs install --dry-run --verbose fish
configz backup fish                    # Backup before changes
configz remove fish                    # Remove when no longer needed
configz restore fish                   # Restore from backup

# Batch operations
configz install fish nvim starship     # Install multiple modules
configz install --all                  # Install everything
configz remove --all                   # Remove everything

# Development workflow
configz init mynewapp                  # Create new module template
configz doctor                         # Check for issues
configz migrate ~/old-dotfiles         # Migrate existing configs
```

## 🛠️ Global Options

| Option | Description |
|--------|-------------|
| `-h, --help` | Show help message |
| `-V, --version` | Show version information |
| `-v, --verbose` | Enable verbose output |
| `-q, --quiet` | Suppress non-error output |
| `-n, --dry-run` | Show what would be done without executing |
| `--no-backup` | Skip automatic backups |
| `-f, --force` | Force operations without confirmation |
| `--config-dir DIR` | Use custom config directory |
| `--modules-dir DIR` | Use custom modules directory |

## 🏗️ Development

```bash
# Clone and setup
git clone https://github.com/Nath-vfx/configz.git
cd configz

# Test locally (without installing)
./configz list

# Install for development
./install-cli.sh

# Check system health
configz doctor
```

## 📜 License

MIT License - see LICENSE file for details.

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## 📖 Documentation

- **[Getting Started](docs/user-guide/getting-started.md)** - Quick setup and first steps
- **[CLI Reference](docs/user-guide/cli-reference.md)** - Complete command documentation  
- **[Examples](docs/user-guide/examples.md)** - Real-world usage examples
- **[Adding Modules](docs/developer-guide/adding-modules.md)** - Create your own modules
- **[Contributing](docs/developer-guide/contributing.md)** - How to contribute
- **[Changelog](docs/CHANGELOG.md)** - Version history

For complete documentation, visit the [docs](docs/) directory.
