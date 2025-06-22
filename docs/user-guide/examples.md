# Configz Examples

This guide provides real-world examples of using Configz to manage your dotfiles and application configurations.

## 🎯 Basic Examples

### Simple Configuration File

Create a module for a basic application:

```bash
# Create module
mkdir -p ~/.config/configz/modules/myapp

# Add configuration
cat > ~/.config/configz/modules/myapp/config.yml << 'EOF'
theme: dark
font_size: 14
auto_save: true
plugins:
  - syntax-highlighting
  - auto-complete
EOF

# Install it
configz install myapp
```

### Multiple Configuration Files

Organize related configurations in one module:

```bash
mkdir -p ~/.config/configz/modules/terminal-suite

# Main terminal config
cat > ~/.config/configz/modules/terminal-suite/alacritty.yml << 'EOF'
window:
  padding:
    x: 10
    y: 10
  
font:
  normal:
    family: "Fira Code"
  size: 12

colors:
  primary:
    background: '0x1e1e1e'
    foreground: '0xd4d4d4'
EOF

# Terminal multiplexer config
cat > ~/.config/configz/modules/terminal-suite/tmux.conf << 'EOF'
# Set prefix to Ctrl-a
set -g prefix C-a
unbind C-b
bind C-a send-prefix

# Split panes using | and -
bind | split-window -h
bind - split-window -v
unbind '"'
unbind %

# Enable mouse mode
set -g mouse on
EOF

# Module metadata
cat > ~/.config/configz/modules/terminal-suite/configz.toml << 'EOF'
[module]
name = "Terminal Suite"
description = "Complete terminal setup with Alacritty and Tmux"
icon = "💻"

[paths]
target = "."
sources = ["alacritty.yml", "tmux.conf"]

[paths.map]
"tmux.conf" = "../.tmux.conf"
EOF

configz install terminal-suite
```

## 🐟 Shell Configuration Examples

### Fish Shell Complete Setup

```bash
mkdir -p ~/.config/configz/modules/fish/{functions,completions,conf.d}

# Main config
cat > ~/.config/configz/modules/fish/config.fish << 'EOF'
# Fish Configuration

# Greeting
set fish_greeting "🐟 Welcome to Fish Shell!"

# Environment variables
set -gx EDITOR nvim
set -gx BROWSER firefox
set -gx TERM xterm-256color

# Path additions
fish_add_path ~/.local/bin
fish_add_path ~/.cargo/bin

# Aliases
alias ll="ls -la"
alias la="ls -la"
alias grep="grep --color=auto"
alias ..="cd .."
alias ...="cd ../.."

# Colors
set -g fish_color_command blue
set -g fish_color_param cyan
set -g fish_color_redirection magenta
set -g fish_color_comment brblack
set -g fish_color_error red
EOF

# Custom function
cat > ~/.config/configz/modules/fish/functions/mkcd.fish << 'EOF'
function mkcd --description "Create directory and cd into it"
    mkdir -p $argv[1]
    and cd $argv[1]
end
EOF

# Git abbreviations
cat > ~/.config/configz/modules/fish/conf.d/git_abbreviations.fish << 'EOF'
# Git abbreviations
abbr -a gs git status
abbr -a ga git add
abbr -a gc git commit
abbr -a gp git push
abbr -a gl git log --oneline
abbr -a gd git diff
abbr -a gb git branch
abbr -a gco git checkout
EOF

# Module configuration
cat > ~/.config/configz/modules/fish/configz.toml << 'EOF'
[module]
name = "Fish Shell"
description = "Complete Fish shell configuration with functions and abbreviations"
icon = "🐟"
version = "2.0.0"

[installation]
type = "copy"

[paths]
target = "fish"
sources = ["config.fish", "functions/", "completions/", "conf.d/"]

[dependencies]
system = ["fish"]

[post_install]
notes = [
    "Set Fish as default shell: chsh -s $(which fish)",
    "Restart terminal to apply changes",
    "Type 'fish_config' to customize further"
]
EOF

configz install fish
```

### Zsh with Oh My Zsh

```bash
mkdir -p ~/.config/configz/modules/zsh

cat > ~/.config/configz/modules/zsh/zshrc << 'EOF'
# Zsh Configuration

# Oh My Zsh
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="powerlevel10k/powerlevel10k"

plugins=(
    git
    docker
    kubectl
    z
    zsh-autosuggestions
    zsh-syntax-highlighting
)

source $ZSH/oh-my-zsh.sh

# Custom aliases
alias ll="ls -la"
alias vim="nvim"
alias cat="bat"
alias find="fd"

# Environment
export EDITOR=nvim
export BROWSER=firefox
export TERM=xterm-256color

# Custom functions
mkcd() { mkdir -p "$1" && cd "$1"; }
extract() {
    if [ -f $1 ] ; then
        case $1 in
            *.tar.bz2)   tar xjf $1     ;;
            *.tar.gz)    tar xzf $1     ;;
            *.bz2)       bunzip2 $1     ;;
            *.rar)       unrar e $1     ;;
            *.gz)        gunzip $1      ;;
            *.tar)       tar xf $1      ;;
            *.tbz2)      tar xjf $1     ;;
            *.tgz)       tar xzf $1     ;;
            *.zip)       unzip $1       ;;
            *.Z)         uncompress $1  ;;
            *.7z)        7z x $1        ;;
            *)     echo "'$1' cannot be extracted via extract()" ;;
        esac
    else
        echo "'$1' is not a valid file"
    fi
}
EOF

cat > ~/.config/configz/modules/zsh/configz.toml << 'EOF'
[module]
name = "Zsh Configuration"
description = "Complete Zsh setup with Oh My Zsh and useful plugins"
icon = "🚀"

[paths]
target = "../"
sources = ["zshrc"]

[paths.map]
"zshrc" = ".zshrc"

[dependencies]
system = ["zsh", "curl", "git"]

[post_install]
notes = [
    "Install Oh My Zsh: sh -c \"$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)\"",
    "Install Powerlevel10k: git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k",
    "Set Zsh as default: chsh -s $(which zsh)"
]
EOF
```

## 🎨 Development Environment Examples

### Complete Neovim Setup

```bash
mkdir -p ~/.config/configz/modules/nvim/{lua,plugin}

# Main init file
cat > ~/.config/configz/modules/nvim/init.lua << 'EOF'
-- Neovim Configuration

-- Leader key
vim.g.mapleader = " "

-- Basic settings
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.expandtab = true
vim.opt.shiftwidth = 2
vim.opt.tabstop = 2
vim.opt.smartindent = true
vim.opt.wrap = false
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.termguicolors = true

-- Key mappings
vim.keymap.set("n", "<leader>w", ":w<CR>")
vim.keymap.set("n", "<leader>q", ":q<CR>")
vim.keymap.set("n", "<C-h>", "<C-w>h")
vim.keymap.set("n", "<C-j>", "<C-w>j")
vim.keymap.set("n", "<C-k>", "<C-w>k")
vim.keymap.set("n", "<C-l>", "<C-w>l")

-- Load plugin configurations
require("plugins")
EOF

# Plugin configuration
cat > ~/.config/configz/modules/nvim/lua/plugins.lua << 'EOF'
-- Plugin Manager: Lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable",
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

-- Plugin specifications
require("lazy").setup({
  -- Color scheme
  {
    "catppuccin/nvim",
    name = "catppuccin",
    config = function()
      vim.cmd.colorscheme "catppuccin"
    end
  },
  
  -- File explorer
  {
    "nvim-tree/nvim-tree.lua",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
      require("nvim-tree").setup()
      vim.keymap.set("n", "<leader>e", ":NvimTreeToggle<CR>")
    end
  },
  
  -- Fuzzy finder
  {
    "nvim-telescope/telescope.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    config = function()
      vim.keymap.set("n", "<leader>ff", ":Telescope find_files<CR>")
      vim.keymap.set("n", "<leader>fg", ":Telescope live_grep<CR>")
    end
  },
  
  -- LSP
  {
    "neovim/nvim-lspconfig",
    config = function()
      local lspconfig = require("lspconfig")
      lspconfig.lua_ls.setup{}
      lspconfig.tsserver.setup{}
      lspconfig.rust_analyzer.setup{}
    end
  }
})
EOF

cat > ~/.config/configz/modules/nvim/configz.toml << 'EOF'
[module]
name = "Neovim"
description = "Complete Neovim configuration with LSP and plugins"
icon = "⚡"
version = "2.0.0"

[paths]
target = "nvim"
sources = ["init.lua", "lua/"]

[dependencies]
system = ["nvim", "git", "ripgrep", "fd"]

[post_install]
notes = [
    "Install language servers as needed",
    "Run :checkhealth in Neovim to verify setup",
    "Plugins will auto-install on first launch"
]
EOF
```

### Git Configuration

```bash
mkdir -p ~/.config/configz/modules/git

cat > ~/.config/configz/modules/git/gitconfig << 'EOF'
[user]
    name = Your Name
    email = your.email@example.com

[core]
    editor = nvim
    autocrlf = input
    pager = delta

[init]
    defaultBranch = main

[push]
    default = simple
    autoSetupRemote = true

[pull]
    rebase = true

[merge]
    conflictstyle = diff3

[diff]
    colorMoved = default

[delta]
    navigate = true
    light = false
    side-by-side = true

[interactive]
    diffFilter = delta --color-only

[alias]
    st = status
    co = checkout
    br = branch
    ci = commit
    ca = commit -a
    cam = commit -am
    unstage = reset HEAD --
    last = log -1 HEAD
    visual = !gitk
    logs = log --oneline --graph --decorate --all
    amend = commit --amend --no-edit
    please = push --force-with-lease
    commend = commit --amend --no-edit
    it = !git init && git commit -m "root" --allow-empty
    stash-all = stash save --include-untracked
    glog = log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset'
EOF

cat > ~/.config/configz/modules/git/gitignore_global << 'EOF'
# Global Git Ignore

# OS Files
.DS_Store
.DS_Store?
._*
.Spotlight-V100
.Trashes
ehthumbs.db
Thumbs.db
Desktop.ini
$RECYCLE_BIN/

# Editor files
*~
*.swp
*.swo
.vscode/
.idea/

# Development
node_modules/
.env
.env.local
*.log
EOF

cat > ~/.config/configz/modules/git/configz.toml << 'EOF'
[module]
name = "Git Configuration"
description = "Complete Git setup with aliases and global gitignore"
icon = "📚"

[paths]
target = "../"
sources = ["gitconfig", "gitignore_global"]

[paths.map]
"gitconfig" = ".gitconfig"
"gitignore_global" = ".gitignore_global"

[dependencies]
system = ["git"]
optional = ["delta"]

[post_install]
notes = [
    "Update name and email in .gitconfig",
    "Install delta for better diffs: brew install git-delta",
    "Set global gitignore: git config --global core.excludesfile ~/.gitignore_global"
]
EOF
```

## 🎵 Multimedia Applications

### MPV Media Player

```bash
mkdir -p ~/.config/configz/modules/mpv/{scripts,script-opts}

cat > ~/.config/configz/modules/mpv/mpv.conf << 'EOF'
# MPV Configuration

# Video
vo=gpu
hwdec=auto
profile=gpu-hq
scale=ewa_lanczossharp
cscale=ewa_lanczossharp

# Audio
ao=pulse
volume-max=200
volume=70

# Subtitles
sub-auto=fuzzy
sub-file-paths=sub:subtitles:Subtitles
slang=en,eng
sub-font-size=45
sub-color="#FFFFFF"
sub-border-color="#000000"
sub-border-size=2

# Interface
osc=no
osd-level=1
osd-duration=2000
cursor-autohide=1000

# Screenshots
screenshot-format=png
screenshot-png-compression=8
screenshot-template='~/Pictures/mpv-screenshot-%F-%P'

# Cache
cache=yes
demuxer-max-bytes=50MiB
demuxer-max-back-bytes=25MiB
EOF

cat > ~/.config/configz/modules/mpv/input.conf << 'EOF'
# MPV Key Bindings

# Playback
SPACE cycle pause
RIGHT seek 10
LEFT seek -10
UP seek 60
DOWN seek -60
Shift+RIGHT seek 600
Shift+LEFT seek -600

# Volume
+ add volume 5
- add volume -5
m cycle mute

# Video
f cycle fullscreen
1 add contrast -1
2 add contrast 1
3 add brightness -1
4 add brightness 1
5 add gamma -1
6 add gamma 1

# Subtitles
v cycle sub-visibility
n cycle sub
N cycle sub down
j cycle sub-pos -1
k cycle sub-pos +1

# Screenshots
s screenshot
S screenshot video
EOF

cat > ~/.config/configz/modules/mpv/configz.toml << 'EOF'
[module]
name = "MPV Media Player"
description = "Optimized MPV configuration for high-quality video playback"
icon = "🎬"

[paths]
target = "mpv"
sources = ["mpv.conf", "input.conf", "scripts/", "script-opts/"]

[dependencies]
system = ["mpv"]

[post_install]
notes = [
    "Install additional codecs if needed",
    "Add custom scripts to ~/.config/mpv/scripts/",
    "Adjust video settings based on your hardware"
]
EOF
```

## 🌐 Web Development Environment

### Complete Web Dev Setup

```bash
mkdir -p ~/.config/configz/modules/webdev

# VS Code settings
cat > ~/.config/configz/modules/webdev/vscode-settings.json << 'EOF'
{
  "editor.fontSize": 14,
  "editor.fontFamily": "'Fira Code', 'Droid Sans Mono', monospace",
  "editor.fontLigatures": true,
  "editor.tabSize": 2,
  "editor.insertSpaces": true,
  "editor.formatOnSave": true,
  "editor.minimap.enabled": false,
  "workbench.colorTheme": "One Dark Pro",
  "workbench.iconTheme": "material-icon-theme",
  "extensions.autoUpdate": false,
  "git.autofetch": true,
  "git.confirmSync": false,
  "emmet.includeLanguages": {
    "javascript": "javascriptreact"
  },
  "prettier.singleQuote": true,
  "prettier.semi": false
}
EOF

# Node.js configuration
cat > ~/.config/configz/modules/webdev/npmrc << 'EOF'
init-author-name=Your Name
init-author-email=your.email@example.com
init-license=MIT
save-exact=true
package-lock=true
EOF

# Prettier config
cat > ~/.config/configz/modules/webdev/prettierrc << 'EOF'
{
  "semi": false,
  "singleQuote": true,
  "tabWidth": 2,
  "trailingComma": "es5",
  "printWidth": 80,
  "arrowParens": "avoid"
}
EOF

cat > ~/.config/configz/modules/webdev/configz.toml << 'EOF'
[module]
name = "Web Development Setup"
description = "Complete web development environment with VS Code, Node.js, and tooling"
icon = "🌐"

[installation]
type = "copy"

[paths]
target = "../"
sources = ["vscode-settings.json", "npmrc", "prettierrc"]

[paths.map]
"vscode-settings.json" = ".config/Code/User/settings.json"
"npmrc" = ".npmrc"
"prettierrc" = ".prettierrc"

[dependencies]
system = ["node", "npm", "code"]

[post_install]
notes = [
    "Install recommended VS Code extensions",
    "Set up global npm packages: npm i -g prettier eslint",
    "Configure Git for web development workflow"
]
EOF
```

## 📊 Data Science Environment

### Python/Jupyter Setup

```bash
mkdir -p ~/.config/configz/modules/datascience

cat > ~/.config/configz/modules/datascience/jupyter_config.py << 'EOF'
# Jupyter Configuration

c = get_config()

# Notebook settings
c.NotebookApp.open_browser = False
c.NotebookApp.ip = '127.0.0.1'
c.NotebookApp.port = 8888
c.NotebookApp.notebook_dir = '~/notebooks'

# Display settings
c.InlineBackend.figure_format = 'retina'
c.InlineBackend.rc = {
    'figure.figsize': (12, 8),
    'font.size': 14,
    'axes.labelsize': 14,
    'axes.titlesize': 16,
    'xtick.labelsize': 12,
    'ytick.labelsize': 12,
    'legend.fontsize': 12
}
EOF

cat > ~/.config/configz/modules/datascience/ipython_config.py << 'EOF'
# IPython Configuration

c = get_config()

# Auto-reload modules
c.InteractiveShellApp.exec_lines = [
    '%load_ext autoreload',
    '%autoreload 2'
]

# Enable rich output
c.TerminalIPythonApp.display_banner = True
c.InteractiveShell.colors = 'Linux'
c.InteractiveShell.confirm_exit = False
EOF

cat > ~/.config/configz/modules/datascience/configz.toml << 'EOF'
[module]
name = "Data Science Environment"
description = "Python data science setup with Jupyter and IPython configurations"
icon = "📊"

[paths]
target = "."
sources = ["jupyter_config.py", "ipython_config.py"]

[paths.map]
"jupyter_config.py" = ".jupyter/jupyter_notebook_config.py"
"ipython_config.py" = ".ipython/profile_default/ipython_config.py"

[dependencies]
system = ["python3", "pip"]
optional = ["jupyter", "ipython", "pandas", "numpy", "matplotlib"]

[post_install]
notes = [
    "Install Jupyter: pip install jupyter",
    "Create notebooks directory: mkdir ~/notebooks",
    "Install data science packages: pip install pandas numpy matplotlib seaborn",
    "Start Jupyter: jupyter notebook"
]
EOF
```

## 🎮 Gaming Configuration

### Steam and Gaming Tools

```bash
mkdir -p ~/.config/configz/modules/gaming

cat > ~/.config/configz/modules/gaming/steam_config.vdf << 'EOF'
"UserLocalConfigStore"
{
    "Software"
    {
        "Valve"
        {
            "Steam"
            {
                "NoSavePersonalInfo"        "0"
                "MaxServerBrowserPingsPerMin"        "5000"
                "DownloadThrottleKbps"        "0"
                "AllowDownloadsDuringGameplay"        "0"
                "StreamingThrottleEnabled"        "1"
                "ClientBrowserAuth"        "0"
            }
        }
    }
}
EOF

cat > ~/.config/configz/modules/gaming/gamemode.ini << 'EOF'
[general]
renice=10
ioprio=1
inhibit_screensaver=1
softrealtime=auto
reaper_freq=5

[filter]
whitelist=
blacklist=

[gpu]
apply_gpu_optimisations=accept-responsibility
gpu_device=0
amd_performance_level=high
EOF

cat > ~/.config/configz/modules/gaming/configz.toml << 'EOF'
[module]
name = "Gaming Configuration"
description = "Optimized gaming setup with Steam and performance tools"
icon = "🎮"

[paths]
target = "."
sources = ["steam_config.vdf", "gamemode.ini"]

[paths.map]
"steam_config.vdf" = ".steam/steam/config/config.vdf"
"gamemode.ini" = ".config/gamemode.ini"

[dependencies]
system = ["steam"]
optional = ["gamemode", "mangohud"]

[post_install]
notes = [
    "Install GameMode: sudo apt install gamemode (Ubuntu) or brew install gamemode (macOS)",
    "Install MangoHud for performance overlay",
    "Restart Steam to apply settings"
]
EOF
```

## 🔧 System Administration

### Complete System Tools Setup

```bash
mkdir -p ~/.config/configz/modules/sysadmin

# Htop configuration
cat > ~/.config/configz/modules/sysadmin/htoprc << 'EOF'
# Htop Configuration
fields=0 48 17 18 38 39 40 2 46 47 49 1
sort_key=46
sort_direction=1
hide_threads=0
hide_kernel_threads=1
hide_userland_threads=0
shadow_other_users=0
show_thread_names=0
show_program_path=1
highlight_base_name=0
highlight_megabytes=1
highlight_threads=1
tree_view=0
header_margin=1
detailed_cpu_time=0
cpu_count_from_zero=0
update_process_names=0
account_guest_in_cpu_meter=0
color_scheme=0
delay=15
left_meters=LeftCPUs Memory Swap
left_meter_modes=1 1 1
right_meters=RightCPUs Tasks LoadAverage Uptime
right_meter_modes=1 2 2 2
EOF

# Systemctl aliases
cat > ~/.config/configz/modules/sysadmin/systemctl_aliases.sh << 'EOF'
# Systemctl aliases
alias sc='systemctl'
alias scu='systemctl --user'
alias scur='systemctl --user daemon-reload'
alias scr='systemctl daemon-reload'
alias scs='systemctl status'
alias scus='systemctl --user status'
alias sce='systemctl enable'
alias scue='systemctl --user enable'
alias scd='systemctl disable'
alias scud='systemctl --user disable'
alias scstart='systemctl start'
alias scustart='systemctl --user start'
alias scstop='systemctl stop'
alias scustop='systemctl --user stop'
alias screstart='systemctl restart'
alias scurestart='systemctl --user restart'

# Journal aliases
alias jc='journalctl'
alias jcu='journalctl --user'
alias jcf='journalctl -f'
alias jcuf='journalctl --user -f'
EOF

cat > ~/.config/configz/modules/sysadmin/configz.toml << 'EOF'
[module]
name = "System Administration Tools"
description = "Configuration for system monitoring and administration tools"
icon = "🔧"

[paths]
target = "."
sources = ["htoprc", "systemctl_aliases.sh"]

[paths.map]
"htoprc" = ".config/htop/htoprc"
"systemctl_aliases.sh" = ".config/shell/systemctl_aliases.sh"

[dependencies]
system = ["htop", "systemctl"]

[post_install]
notes = [
    "Source aliases in your shell config",
    "Install additional monitoring tools: iotop, nethogs, etc.",
    "Consider setting up log rotation"
]
EOF
```

## 🤖 Batch Operations Examples

### Install Multiple Related Modules

```bash
# Create development environment
configz install fish nvim git

# Set up multimedia workstation
configz install mpv obs-studio blender

# Configure web development environment
configz install webdev nodejs-tools browser-extensions

# Gaming setup
configz install gaming steam discord

# System administration toolkit
configz install sysadmin monitoring-tools security-config
```

### Environment-Specific Installations

```bash
# Development machine
configz --modules-dir ~/dev-configs install \
  development-fish \
  nvim-dev \
  git-dev \
  docker-dev

# Production server
configz --modules-dir ~/server-configs --config-dir /opt/config install \
  server-monitoring \
  nginx-config \
  security-hardening

# Personal laptop
configz install \
  personal-fish \
  multimedia-apps \
  productivity-tools
```

### Backup and Migration

```bash
# Backup all current configurations
configz backup --all

# Migrate from old dotfiles repository
configz migrate ~/old-dotfiles/

# Selective restoration
configz restore fish nvim git

# Clean installation with backup
configz remove --all
configz install fish nvim git starship
```

## 💡 Pro Tips

### 1. Module Versioning
```bash
# Create versioned modules
mkdir ~/.config/configz/modules/nvim-v1
mkdir ~/.config/configz/modules/nvim-v2

# Switch between versions
configz remove nvim-v1
configz install nvim-v2
```

### 2. Conditional Modules
Create modules that work differently on different systems by using environment checks in `configz.toml`.

### 3. Shared Module Repository
```bash
# Keep modules in version control
cd ~/.config/configz/modules
git init
git remote add origin https://github.com/yourusername/my-dotfiles
git push -u origin main

# On new machine
git clone https://github.com/yourusername/my-dotfiles ~/.config/configz/modules
configz install --all
```

### 4. Testing New Configurations
```bash
# Test in temporary directory
configz --config-dir /tmp/test-config install experimental-module

# Use dry-run for safety
configz install --dry-run risky-module

# Backup before major changes
configz backup --all
```

---

These examples should give you a solid foundation for creating your own configuration modules. Remember to start simple and gradually add complexity as you become more comfortable with Configz!