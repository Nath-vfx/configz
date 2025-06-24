# Contributing to Configz

Thank you for your interest in contributing to Configz! This guide will help you get started with contributing to the project.

## 🚀 Getting Started

### Prerequisites

- **Bash 4.0+** (macOS users: `brew install bash`)
- **Git** for version control
- **Basic shell scripting knowledge**
- **Understanding of configuration management concepts**

### Development Setup

```bash
# Fork the repository on GitHub
# Clone your fork
git clone https://github.com/Nath-vfx/configz.git
cd configz

# Set up upstream remote
git remote add upstream https://github.com/Nath-vfx/configz.git

# Create development branch
git checkout -b feature/your-feature-name
```

## 🏗️ Project Structure

```
configz/
├── cli/                       # CLI source code
│   ├── commands/              # Individual command implementations
│   │   ├── list.sh           # List command
│   │   ├── install.sh        # Install command
│   │   └── ...               # Other commands
│   └── lib/                  # Shared libraries
│       └── common.sh         # Common functions
├── completions/              # Shell completions
│   └── configz.fish         # Fish shell completion
├── docs/                     # Documentation
│   ├── user-guide/          # User documentation
│   └── developer-guide/     # Developer documentation
├── configz                   # Main CLI executable
└── install-cli.sh           # Installation script
```

## 🛠️ Development Workflow

### 1. Making Changes

```bash
# Always work on feature branches
git checkout -b feature/new-command

# Make your changes
vim cli/commands/new-command.sh

# Test your changes locally
./configz new-command --help
./configz new-command --dry-run
```

### 2. Testing

```bash
# Test CLI functionality
./configz doctor
./configz list
./configz --help

# Test with different options
./configz --modules-dir /tmp/test-modules list
./configz --verbose install test-module

# Test error conditions
./configz invalid-command
./configz install non-existent-module
```

### 3. Code Style

- **Follow existing patterns** in the codebase
- **Use consistent indentation** (2 spaces)
- **Add comments** for complex logic
- **Use descriptive variable names**
- **Follow bash best practices**

```bash
# Good
local module_name="$1"
local target_path="$CONFIG_TARGET_DIR/$module_name"

# Bad
local m="$1"
local tp="$CONFIG_TARGET_DIR/$m"
```

## 📝 Adding New Commands

### 1. Command Structure

Create a new file in `cli/commands/`:

```bash
#!/usr/bin/env bash

# Command: configz mycommand
# Description: Brief description of what the command does

# Source common functions
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"

# Command-specific help
show_mycommand_help() {
    cat << EOF
Usage: $PROGRAM_NAME mycommand [OPTIONS] [ARGS...]

Description of what the command does.

OPTIONS:
    -h, --help          Show this help message
    -v, --verbose       Enable verbose output
    --option VALUE      Description of option

EXAMPLES:
    $PROGRAM_NAME mycommand
    $PROGRAM_NAME mycommand --option value

EOF
}

# Main command function
cmd_mycommand() {
    local verbose=0
    local option_value=""
    
    # Parse command-specific options
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_mycommand_help
                exit 0
                ;;
            -v|--verbose)
                verbose=1
                shift
                ;;
            --option)
                option_value="$2"
                shift 2
                ;;
            -*)
                log_error "Unknown option: $1"
                show_mycommand_help
                exit 1
                ;;
            *)
                # Handle positional arguments
                break
                ;;
        esac
    done
    
    # Command implementation
    log_info "Executing mycommand..."
    
    # Your command logic here
    
    log_success "Command completed successfully!"
}

# Export the command function
declare -fx cmd_mycommand
```

### 2. Register the Command

Add your command to the main `configz` script:

```bash
# In the main case statement
case "$COMMAND" in
    # ... existing commands ...
    mycommand)
        source "$CLI_DIR/commands/mycommand.sh"
        cmd_mycommand "$@"
        ;;
```

### 3. Add Completion

Update `completions/configz.fish`:

```fish
# Add your command to the list
complete -c configz -f -n '__fish_use_subcommand' -a mycommand -d 'Description of mycommand'

# Add command-specific options
complete -c configz -f -n '__fish_seen_subcommand_from mycommand' -l option -d 'Description of option'
```

## 📚 Documentation

### 1. Command Documentation

- Add help text to your command using `show_COMMAND_help()`
- Include usage examples
- Document all options and arguments
- Follow the existing format

### 2. User Documentation

Update relevant documentation files:

- `docs/user-guide/cli-reference.md` - Add command reference
- `docs/user-guide/examples.md` - Add usage examples
- `docs/README.md` - Update if needed

### 3. Developer Documentation

- Document any new internal APIs
- Update this contributing guide if you change the development process
- Add comments to complex code

## 🧪 Testing Guidelines

### 1. Manual Testing

Test your changes thoroughly:

```bash
# Test normal operation
./configz mycommand

# Test error conditions
./configz mycommand --invalid-option
./configz mycommand missing-argument

# Test with different verbosity levels
./configz --verbose mycommand
./configz --quiet mycommand

# Test with different paths
./configz --modules-dir /tmp/test mycommand
```

### 2. Edge Cases

Consider and test edge cases:

- Empty modules directory
- Permission denied scenarios
- Invalid module configurations
- Network connectivity issues (if applicable)
- Different operating systems

### 3. Backwards Compatibility

Ensure your changes don't break existing functionality:

- Test existing commands still work
- Verify no regression in output format
- Check that scripts using configz still function

## 🐛 Bug Reports

### 1. Before Reporting

- Check if the issue already exists
- Try to reproduce with minimal steps
- Test with the latest version

### 2. Good Bug Report

Include:

- **Environment details** (OS, Bash version, etc.)
- **Steps to reproduce**
- **Expected behavior**
- **Actual behavior**
- **Error messages** (full output with `--verbose`)
- **Relevant configuration** (sanitized)

```bash
# Helpful debug information
configz doctor
configz --version
echo $BASH_VERSION
uname -a
```

## ✨ Feature Requests

### 1. Feature Proposal Format

- **Problem description** - What issue does this solve?
- **Proposed solution** - How should it work?
- **Alternatives considered** - What other approaches were considered?
- **Use cases** - Real-world scenarios where this would be useful

### 2. Implementation Discussion

- Discuss the feature before implementing
- Consider backwards compatibility
- Think about edge cases and error handling
- Plan the user interface and documentation

## 🔄 Pull Request Process

### 1. Before Submitting

```bash
# Sync with upstream
git fetch upstream
git rebase upstream/main

# Test thoroughly
./configz doctor
# ... run your tests ...

# Clean up commits
git rebase -i upstream/main
```

### 2. Pull Request Checklist

- [ ] **Feature/fix is complete** and tested
- [ ] **Code follows project style** and conventions
- [ ] **Tests pass** (manual testing)
- [ ] **Documentation updated** as needed
- [ ] **Commit messages are clear** and descriptive
- [ ] **No merge conflicts** with main branch

### 3. Pull Request Description

```markdown
## Description
Brief description of changes and motivation.

## Type of Change
- [ ] Bug fix
- [ ] New feature
- [ ] Documentation update
- [ ] Code refactoring

## Testing
- Describe testing performed
- Include test commands/scenarios

## Checklist
- [ ] Code follows style guidelines
- [ ] Self-review completed
- [ ] Documentation updated
- [ ] No breaking changes (or clearly documented)
```

## 📋 Code Review Guidelines

### 1. As a Reviewer

- **Be constructive** and helpful
- **Ask questions** if something is unclear
- **Suggest alternatives** when appropriate
- **Test the changes** if possible
- **Focus on** functionality, readability, and maintainability

### 2. As an Author

- **Respond promptly** to feedback
- **Be open** to suggestions and changes
- **Explain your reasoning** when disagreeing
- **Update documentation** based on feedback
- **Test again** after making changes

## 🏷️ Release Process

### 1. Version Numbering

We use semantic versioning (MAJOR.MINOR.PATCH):

- **MAJOR** - Incompatible API changes
- **MINOR** - New functionality (backwards compatible)
- **PATCH** - Bug fixes (backwards compatible)

### 2. Release Checklist

- [ ] All tests pass
- [ ] Documentation is updated
- [ ] CHANGELOG.md is updated
- [ ] Version number is bumped
- [ ] Git tag is created
- [ ] Release notes are written

## 🤝 Community Guidelines

### 1. Code of Conduct

- **Be respectful** and inclusive
- **Help others** learn and contribute
- **Give constructive feedback**
- **Focus on** what's best for the project
- **Acknowledge contributions** of others

### 2. Communication

- **Use GitHub issues** for bug reports and feature requests
- **Use pull requests** for code contributions
- **Be patient** - maintainers are volunteers
- **Search existing issues** before creating new ones

## 🛠️ Development Tips

### 1. Debugging

```bash
# Enable bash debugging
bash -x ./configz command

# Add debug output
log_debug "Debug message here"

# Test with verbose mode
./configz --verbose command
```

### 2. Common Patterns

```bash
# Error handling
if ! command_that_might_fail; then
    log_error "Command failed"
    return 1
fi

# Optional dependencies
if command -v optional_tool >/dev/null 2>&1; then
    log_info "Using optional_tool for enhanced functionality"
    use_optional_tool
else
    log_info "optional_tool not found, using fallback"
    use_fallback
fi

# File operations with error checking
if [[ ! -f "$config_file" ]]; then
    log_error "Configuration file not found: $config_file"
    return 1
fi
```

### 3. Performance Considerations

- **Avoid** unnecessary subshells and external commands
- **Use** bash built-ins when possible
- **Cache** expensive operations
- **Test** with large numbers of modules

## 📞 Getting Help

### 1. Where to Ask

- **GitHub Issues** - For bugs and feature requests
- **GitHub Discussions** - For general questions and ideas
- **Code comments** - For specific implementation questions

### 2. What to Include

- **Context** about what you're trying to achieve
- **Code examples** or error messages
- **Environment details** when relevant
- **What you've already tried**

---

Thank you for contributing to Configz! Your help makes this project better for everyone. 🎉