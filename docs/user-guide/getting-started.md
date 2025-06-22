# Getting Started with Configz

Welcome to Configz! This guide will help you get up and running with the modern configuration management CLI in just a few minutes.

## 🚀 Installation

### Prerequisites

- **Bash 4.0+** (macOS users: `brew install bash` for latest version)
- **Git** (for cloning the repository)
- **Basic shell knowledge**

### Install Configz

```bash
# Clone the repository
git clone https://github.com/yourusername/configz.git
cd configz

# Install the CLI globally
./install-cli.sh

# Verify installation
configz --version
```

## 🏗️ First Time Setup

### 1. Create Your Modules Directory

```bash
# Create the default modules directory
mkdir -p ~/.config/configz/modules

# Verify it was created
ls -la ~/.config/configz/
```

### 2. Check System Health

```bash
# Run system diagnostics
configz doctor

# This will check:
# - Required dependencies
# - Directory permissions
# - System compatibility
```

## 📦 Understanding Modules

A **module** is a directory containing configuration files for a specific application or tool.

### Module Structure
```
~/.config/configz/modules/
├── fish/                      # Module name
│   ├── config.fish           # Configuration files
│   ├── functions/            # Subdirectories allowed
│   └── configz.toml          # Optional metadata
└── starship/
    ├── starship.toml
    └── configz.toml
```

### What Makes a Module?
- **Directory name** = Module name
- **Any files inside** = Configuration to install
- **Optional `configz.toml`** = Advanced settings

## 🎯 Your First Module

### Option 1: Create from Scratch

```bash
# Create module directory
mkdir ~/.config/configz/modules/my-app

# Add a configuration file
cat > ~/.config/configz/modules/my-app/config.conf << 'EOF'
# My App Configuration
theme=dark
font_size=14
auto_save=true
EOF

# The module is now available!
configz list
```

### Option 2: Use the Template Generator

```bash
# Generate a module template
configz init my-app

# This creates:
# ~/.config/configz/modules/my-app/
# ├── configz.toml (with metadata template)
# └── README.md (with instructions)
```

## 📋 Basic Commands

### List Available Modules

```bash
# Show all modules
configz list

# Show only installed modules
configz list --installed

# Detailed view
configz list --long
```

### Get Module Information

```bash
# Show detailed info about a module
configz info my-app

# Show installation status
configz status my-app
```

### Install Modules

```bash
# Install a single module
configz install my-app

# Install multiple modules
configz install fish starship nvim

# Preview what would be installed (dry run)
configz install --dry-run my-app
```

### Check Installation Status

```bash
# Status of all modules
configz status

# Status of specific module
configz status my-app
```

## 🔒 Backup and Safety

Configz automatically creates backups before installing anything.

### Automatic Backups

```bash
# Install with automatic backup (default)
configz install fish

# This creates a backup like:
# ~/.config/fish/config.fish.backup.20240320_143022
```

### Manual Backup Control

```bash
# Install without backup
configz install --no-backup fish

# Create backup manually
configz backup fish

# Restore from backup
configz restore fish
```

## 🛠️ Customization

### Custom Directories

```bash
# Use custom modules directory
configz --modules-dir ~/my-configs list

# Use custom target directory
configz --config-dir ~/custom-config install fish

# Combine both
configz --modules-dir ~/my-configs --config-dir ~/dotfiles install fish
```

### Environment Variables

```bash
# Set custom paths permanently
export CONFIGZ_MODULES_DIR="~/my-configs"
export CONFIGZ_CONFIG_DIR="~/my-dotfiles"

# Now all commands use these paths
configz list
```

## 📖 Real-World Example

Let's create and install a complete Fish shell configuration:

### 1. Create the Module

```bash
# Create Fish module directory
mkdir -p ~/.config/configz/modules/fish

# Add main configuration
cat > ~/.config/configz/modules/fish/config.fish << 'EOF'
# Fish Shell Configuration

# Set greeting
set fish_greeting "🐟 Welcome to Fish Shell!"

# Add custom functions directory to path
set -gx fish_function_path $fish_function_path ~/.config/fish/functions

# Enable vi mode
fish_vi_key_bindings

# Set editor
set -gx EDITOR nvim

# Custom prompt colors
set -g fish_color_command blue
set -g fish_color_param cyan
EOF

# Create functions directory and add a custom function
mkdir -p ~/.config/configz/modules/fish/functions
cat > ~/.config/configz/modules/fish/functions/ll.fish << 'EOF'
function ll --description "List files with details"
    ls -la $argv
end
EOF

# Add module metadata
cat > ~/.config/configz/modules/fish/configz.toml << 'EOF'
[module]
name = "Fish Shell"
description = "Modern shell with intelligent autocompletion"
icon = "🐟"
version = "1.0.0"
author = "Your Name"

[installation]
type = "copy"

[paths]
target = "fish"
sources = ["config.fish", "functions/"]

[dependencies]
system = ["fish"]

[post_install]
notes = [
    "Set Fish as your default shell: chsh -s $(which fish)",
    "Restart your terminal to see changes"
]

[backup]
strategy = "auto"
files = ["config.fish"]
directories = ["functions"]
EOF
```

### 2. Install the Module

```bash
# Check if Fish is available
which fish

# Preview the installation
configz install --dry-run fish

# Install it
configz install fish

# Verify installation
configz status fish
ls -la ~/.config/fish/
```

### 3. Test the Configuration

```bash
# Start Fish shell (if installed)
fish

# Test custom function
ll

# Exit back to previous shell
exit
```

## 🔍 Troubleshooting

### Module Not Found

```bash
# Check modules directory exists
ls -la ~/.config/configz/modules/

# Check specific module
ls -la ~/.config/configz/modules/my-app/

# Verify module has files
find ~/.config/configz/modules/my-app/ -type f
```

### Installation Issues

```bash
# Use verbose output for debugging
configz install --verbose my-app

# Check system health
configz doctor

# Check target directory permissions
ls -la ~/.config/
```

### Permission Problems

```bash
# Fix modules directory permissions
chmod -R 755 ~/.config/configz/modules/

# Fix target directory permissions
chmod 755 ~/.config/
```

## 🎓 Next Steps

Now that you have the basics down, explore these advanced features:

1. **[CLI Reference](cli-reference.md)** - Complete command documentation
2. **[Adding Modules](../developer-guide/adding-modules.md)** - Create advanced modules
3. **[Examples](examples.md)** - Real-world configuration examples

### Recommended Workflow

1. **Start simple** - Create basic modules with just config files
2. **Add metadata** - Use `configz.toml` for better organization
3. **Test thoroughly** - Always use `--dry-run` first
4. **Backup important configs** - Use manual backups for critical files
5. **Version control** - Keep your modules in a git repository

## 🤔 Common Questions

**Q: Where should I put my modules?**
A: Default location is `~/.config/configz/modules/`, but you can use any directory with `--modules-dir`

**Q: Can I share modules with others?**
A: Yes! Modules are just directories with files. Share via git, zip, or any file sharing method.

**Q: What happens if I already have configuration files?**
A: Configz creates automatic backups before installing, so your existing files are safe.

**Q: Can I uninstall modules?**
A: Yes, use `configz remove <module>` to uninstall and optionally restore backups.

**Q: How do I update a module?**
A: Currently, reinstall with `configz install <module>`. It will backup and replace existing files.

---

**Ready for more?** Check out the [CLI Reference](cli-reference.md) for complete command documentation!