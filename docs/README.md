# Configz Documentation

Welcome to the Configz documentation! This guide will help you get started with the modern configuration management CLI.

## 📚 Documentation Structure

### 👤 User Guide
- **[Getting Started](user-guide/getting-started.md)** - Quick setup and first steps
- **[CLI Reference](user-guide/cli-reference.md)** - Complete command reference
- **[Examples](user-guide/examples.md)** - Real-world usage examples

### 🛠️ Developer Guide
- **[Adding Modules](developer-guide/adding-modules.md)** - Create your own configuration modules
- **[Contributing](developer-guide/contributing.md)** - How to contribute to Configz
- **[API Reference](developer-guide/api-reference.md)** - Internal API documentation

### 📋 Other Resources
- **[Changelog](CHANGELOG.md)** - Version history and release notes

## 🚀 Quick Start

```bash
# Install the CLI
./install-cli.sh

# Create your modules directory
mkdir -p ~/.config/configz/modules

# List available modules
configz list

# Create your first module
configz init my-app
```

## 📖 What is Configz?

Configz is a modern, modular configuration management system that helps you:

- **Organize** your dotfiles and application configurations
- **Install** configurations with automatic backups
- **Manage** multiple environments and setups
- **Share** configuration modules easily
- **Customize** installation paths and behavior

## 🎯 Key Features

- 🎯 **Modern CLI** with intuitive commands and colorful output
- 📦 **Auto-discovery** of configuration modules
- 🔒 **Automatic backups** with timestamped snapshots
- 🛠️ **Customizable paths** for modules and target directories
- ⚡ **Batch operations** with progress indicators
- 🎨 **Rich output** with icons, colors, and detailed information

## 🏗️ Architecture

```
~/.config/configz/
├── modules/                   # Your configuration modules
│   ├── fish/                  # Fish shell configuration
│   ├── nvim/                  # Neovim configuration
│   └── starship/              # Starship prompt
├── backups/                   # Automatic backups
└── config.toml               # Global settings
```

## 📍 Default Locations

| Path | Purpose |
|------|---------|
| `~/.config/configz/modules/` | Your configuration modules |
| `~/.config/configz/backups/` | Automatic backups |
| `~/.config/configz/config.toml` | Global configuration |
| `~/.config/` | Default target for installations |

## 🆘 Getting Help

- **Command help**: `configz --help` or `configz <command> --help`
- **System check**: `configz doctor`
- **Verbose output**: Add `--verbose` to any command
- **Issues**: Report bugs on GitHub

## 🔗 External Resources

- **GitHub Repository**: [https://github.com/yourusername/configz](https://github.com/yourusername/configz)
- **Examples Repository**: [https://github.com/configz/examples](https://github.com/configz/examples)
- **Community Modules**: [https://github.com/configz/modules](https://github.com/configz/modules)

---

**Ready to get started?** Head over to the [Getting Started Guide](user-guide/getting-started.md)!