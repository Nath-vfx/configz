# Configz Documentation

**Version : 0.4.0-alpha**

Welcome to the Configz documentation! This guide will help you get started with the modern configuration management CLI.

> **Note:** This is an alpha version. The CLI interface and features are still evolving.

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

### Installation

```bash
# Clone the repository
git clone https://github.com/Nath-vfx/configz.git
cd configz

# Install the CLI globally
./install-cli.sh

# Start using it
configz --version   # -> must show 0.4.0-alpha
```

### First Steps

```bash
# Initialize a new module
configz init my-module

# List available modules
configz list

# Install a module
configz install my-module

# Check module status
configz status
```

## 🚧 Upcoming Features

The following features are planned for future versions:

- `configz restore` - Restore configurations from backup
- `configz search` - Search for available modules
- `configz update` - Update installed modules
- `configz doctor` - Check system health and dependencies

## 📖 What is Configz?

Configz is a modern, modular configuration management system that helps you:

- **Organize** your dotfiles and application configurations
- **Install** configurations with automatic backups
- **Manage** multiple environments and setups
- **Share** configuration modules easily
- **Customize** installation paths and behavior

## 🎯 Key Features

- 🎯 **Modern CLI** with intuitive commands and colorful output
- 📦 **Auto-discovery** - Automatically detects modules in your modules directory
- ⚙️ **Simple configuration** - Basic `configz.toml` file generation
- 🔒 **Safe operations** - No destructive actions without confirmation
- 🎨 **Rich output** with colors and clear feedback
- 🔧 **Extensible** - Add a directory = new module available
- ⚡ **Fast and lightweight** - Minimal dependencies, fast execution

## 🏗️ Project Structure

```
~/.config/configz/
├── modules/                   # Your configuration modules
│   ├── module-name/           # Example module
│   │   ├── configz.toml      # Module configuration
│   │   └── ...               # Your configuration files
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

## 🛠️ Available Commands

| Command | Description |
|---------|-------------|
| `init <name>` | Create a new module |
| `list` | List available modules |
| `install <module>` | Install a module |
| `info <module>` | Show module details |
| `status` | Show installation status |
| `--help` | Show help message |
| `--version` | Show version information |

## 🆘 Getting Help

- **Command help**: `configz --help` or `configz <command> --help`
- **Verbose output**: Add `-v` or `--verbose` to any command
- **Debug mode**: Set `CONFIGZ_DEBUG=1` for detailed debug output
- **Issues**: Report bugs on [GitHub Issues](https://github.com/Nath-vfx/configz/issues)

## 🔗 External Resources

- **GitHub Repository**: [https://github.com/Nath-vfx/configz](https://github.com/Nath-vfx/configz)

---

**Ready to get started?** Head over to the [Getting Started Guide](user-guide/getting-started.md)!
