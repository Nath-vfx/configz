# Adding Modules to Configz

This guide explains how to create and manage configuration modules in Configz.

## 📍 Quick Start

### 1. Create Your First Module

```bash
# Create a simple module directory
mkdir -p ~/.config/configz/modules/myapp

# Add your configuration files
echo "theme=dark" > ~/.config/configz/modules/myapp/config.conf
echo "font_size=14" >> ~/.config/configz/modules/myapp/config.conf

# The module is now automatically available
configz list
```

### 2. Install Your Module

```bash
# Install the module
configz install myapp

# Check installation status
configz status myapp
```

That's it! Your configuration is now installed to `~/.config/myapp/`.

## 📁 Module Structure

### Basic Module (Auto-detected)
```
~/.config/configz/modules/myapp/
├── config.conf                # Your configuration files
├── themes.json                # Additional config files
└── keybindings.txt            # Any number of files
```

### Advanced Module (With Metadata)
```
~/.config/configz/modules/myapp/
├── configz.toml               # Module metadata (optional)
├── config.conf                # Configuration files
├── themes/                    # Subdirectories supported
│   ├── dark.json
│   └── light.json
└── scripts/                   # Any file structure
    └── setup.sh
```

## ⚙️ Module Configuration (configz.toml)

The `configz.toml` file provides metadata and installation instructions for your module.

### Basic Example

```toml
[module]
name = "My Application"
description = "Custom configuration for my application"
icon = "🚀"
version = "1.0.0"
author = "Your Name"

[installation]
type = "copy"

[paths]
target = "myapp"
sources = ["config.conf", "themes/"]
```

### Complete Example

```toml
[module]
name = "Fish Shell"
description = "Modern shell with intelligent autocompletion"
icon = "🐟"
version = "2.1.0"
author = "Configz Team"
homepage = "https://fishshell.com"
documentation = "https://fishshell.com/docs/"

[installation]
# Installation type: "copy" or "symlink"
type = "copy"
# Custom installation function (advanced)
# custom_function = "install_fish_custom"

[paths]
# Target directory relative to ~/.config/
target = "fish"
# Files/directories to install (relative to module directory)
sources = [
    "config.fish",
    "functions/",
    "completions/",
    "conf.d/"
]
# Files to exclude from installation
exclude = [
    "*.backup",
    "temp/",
    ".DS_Store"
]

[dependencies]
# Required system packages
system = ["fish"]
# Other configz modules that should be installed first
modules = ["starship"]
# Optional dependencies (won't fail if missing)
optional = ["fzf", "bat"]

[post_install]
# Messages to display after installation
notes = [
    "Set Fish as your default shell: chsh -s $(which fish)",
    "Restart your terminal to see changes",
    "Run 'fish_config' to customize further"
]
# Commands to run after installation (use with caution)
commands = [
    "fish -c 'echo Configuration installed successfully'"
]

[backup]
# Backup strategy: "auto", "manual", or "none"
strategy = "auto"
# Specific files to backup
files = ["config.fish"]
# Directories to backup
directories = ["functions", "completions"]
# Files to never backup
exclude_backup = ["cache/", "*.tmp"]

[validation]
# Commands to validate installation
check_commands = [
    "fish --version",
    "test -f ~/.config/fish/config.fish"
]
# Files that must exist after installation
required_files = ["config.fish"]

[metadata]
# Additional metadata for organization
tags = ["shell", "terminal", "productivity"]
category = "shell"
maintainer = "user@example.com"
```

## 🎯 Installation Types

### Copy Installation (Default)
```toml
[installation]
type = "copy"
```
- Copies files to the target directory
- Safe and independent
- Files can be modified without affecting the source

### Symlink Installation
```toml
[installation]
type = "symlink"
```
- Creates symbolic links to the source files
- Changes to source files affect the installation
- Useful for development or shared configurations

## 📂 Path Configuration

### Simple Target
```toml
[paths]
target = "myapp"  # Installs to ~/.config/myapp/
```

### Custom Target Path
```toml
[paths]
target = "../.local/share/myapp"  # Installs to ~/.local/share/myapp/
```

### Specific Sources
```toml
[paths]
target = "myapp"
sources = [
    "config.conf",      # Single file
    "themes/",          # Entire directory
    "scripts/*.sh"      # Glob patterns (if supported)
]
```

### Advanced Path Mapping
```toml
[paths]
target = "myapp"

# Map specific files to different locations
[paths.map]
"init.conf" = "config.conf"
"themes/" = "user-themes/"
```

## 🔧 Dependencies

### System Dependencies
```toml
[dependencies]
system = ["git", "curl", "fish"]
```

### Module Dependencies
```toml
[dependencies]
modules = ["base-config", "theme-manager"]
```

### Optional Dependencies
```toml
[dependencies]
optional = ["fzf", "ripgrep"]  # Won't fail if missing
```

## 📋 Post-Installation Actions

### Information Messages
```toml
[post_install]
notes = [
    "Remember to restart the application",
    "Check the configuration with: myapp --verify",
    "Documentation: https://myapp.example.com/docs"
]
```

### Commands (Use with Caution)
```toml
[post_install]
commands = [
    "myapp --reload-config",
    "systemctl --user reload myapp"
]
```

## 🔒 Backup Configuration

### Automatic Backups (Default)
```toml
[backup]
strategy = "auto"
```
- Creates timestamped backups before installation
- Format: `filename.backup.20240320_143022`

### Manual Backups
```toml
[backup]
strategy = "manual"
```
- Only creates backups when explicitly requested
- User must run `configz backup <module>`

### No Backups
```toml
[backup]
strategy = "none"
```
- Never creates backups
- Use only if you're sure about what you're doing

### Selective Backup
```toml
[backup]
strategy = "auto"
files = ["important.conf"]
directories = ["themes/"]
exclude_backup = ["cache/", "*.tmp"]
```

## ✅ Validation

### Command Validation
```toml
[validation]
check_commands = [
    "myapp --version",
    "test -f ~/.config/myapp/config.conf"
]
```

### File Validation
```toml
[validation]
required_files = [
    "config.conf",
    "themes/default.json"
]
required_directories = [
    "plugins/",
    "themes/"
]
```

## 🏷️ Organization and Metadata

### Tags and Categories
```toml
[metadata]
tags = ["editor", "development", "productivity"]
category = "development"
maintainer = "user@example.com"
```

### Documentation Links
```toml
[module]
homepage = "https://myapp.example.com"
documentation = "https://docs.myapp.example.com"
repository = "https://github.com/user/myapp-config"
```

## 📝 Best Practices

### 1. Module Naming
- Use lowercase names with hyphens: `my-app`, `fish-shell`
- Keep names descriptive but concise
- Avoid special characters and spaces

### 2. File Organization
```
myapp/
├── configz.toml           # Module metadata
├── config.conf            # Main configuration
├── themes/                # Organized subdirectories
│   ├── dark.json
│   └── light.json
├── scripts/               # Related scripts
│   └── post-install.sh
└── README.md             # Module documentation
```

### 3. Configuration Files
- Include only necessary configuration files
- Remove personal data (API keys, personal paths)
- Use relative paths when possible
- Document any manual setup steps

### 4. Testing Your Module
```bash
# Test module detection
configz list | grep myapp

# Test installation (dry run)
configz install --dry-run myapp

# Test actual installation
configz install myapp

# Verify installation
configz status myapp
configz info myapp
```

### 5. Version Control
```bash
# If you want to version control your modules
cd ~/.config/configz/modules
git init
git add .
git commit -m "Initial modules setup"

# Consider using a separate repository for modules
git clone https://github.com/yourusername/my-dotfiles.git ~/.config/configz/modules
```

## 🔄 Module Templates

### Create Module Template
```bash
# Use built-in template creation
configz init myapp

# This creates:
# ~/.config/configz/modules/myapp/
# ├── configz.toml (with basic metadata)
# └── README.md (with instructions)
```

### Custom Templates
Create your own templates in `~/.config/configz/templates/`:

```bash
mkdir -p ~/.config/configz/templates/webapp
cat > ~/.config/configz/templates/webapp/configz.toml << 'EOF'
[module]
name = "{{MODULE_NAME}}"
description = "Web application configuration"
icon = "🌐"
version = "1.0.0"
author = "{{AUTHOR}}"

[installation]
type = "copy"

[paths]
target = "{{MODULE_NAME}}"
sources = ["config.json", "themes/"]

[dependencies]
system = ["nodejs", "npm"]

[post_install]
notes = [
    "Run 'npm install' in the application directory",
    "Start the application with: npm start"
]
EOF
```

## 🚨 Troubleshooting

### Module Not Detected
1. Check directory location: `ls ~/.config/configz/modules/`
2. Verify directory name (no spaces, special characters)
3. Ensure module contains at least one file
4. Check permissions: `ls -la ~/.config/configz/modules/myapp/`

### Installation Fails
1. Check `configz.toml` syntax: `configz info myapp`
2. Verify dependencies are installed
3. Check target directory permissions
4. Use `--verbose` flag for detailed output: `configz install --verbose myapp`

### Backup Issues
1. Check available disk space
2. Verify backup directory permissions
3. Check for long file names (some filesystems have limits)

### Validation Errors
1. Check if validation commands are in PATH
2. Verify required files exist in module
3. Test validation commands manually

## 📚 Advanced Topics

### Custom Installation Functions
For complex installations, you can define custom functions:

```bash
# In your shell configuration or separate script
install_myapp_custom() {
    local module_path="$1"
    local target_path="$2"
    
    # Custom installation logic here
    echo "Running custom installation for myapp..."
    
    # Example: compile configuration files
    compile_config "$module_path/config.template" "$target_path/config.conf"
    
    # Example: set permissions
    chmod 600 "$target_path/secrets.conf"
    
    return 0
}
```

Then reference it in `configz.toml`:
```toml
[installation]
type = "custom"
custom_function = "install_myapp_custom"
```

### Environment-Specific Configurations
```toml
[environments.development]
target = "myapp-dev"
sources = ["config.dev.json"]

[environments.production]
target = "myapp"
sources = ["config.prod.json"]
```

### Conditional Installation
```toml
[conditions]
os = ["linux", "darwin"]  # Only install on Linux/macOS
shell = ["fish", "zsh"]    # Only if using specific shells
commands = ["git", "curl"] # Only if commands are available
```

## 🎉 Examples Repository

Check out the [Configz Examples Repository](https://github.com/configz/examples) for:
- Real-world module examples
- Popular application configurations
- Community-contributed modules
- Best practices implementations

## 💡 Tips and Tricks

1. **Start Simple**: Begin with basic modules and add complexity as needed
2. **Test Thoroughly**: Always test modules before sharing or using in production
3. **Document Everything**: Include README files and clear descriptions
4. **Use Version Control**: Keep your modules in a git repository
5. **Share Modules**: Consider contributing useful modules to the community
6. **Keep Updated**: Regularly update modules as applications change
7. **Backup Before Changes**: Always backup before making major changes
8. **Use Dry Run**: Test installations with `--dry-run` first

---

For more information, see:
- [CLI Guide](CLI_GUIDE.md) - Complete CLI documentation
- [README](README.md) - Getting started guide
- [Examples](https://github.com/configz/examples) - Real-world examples