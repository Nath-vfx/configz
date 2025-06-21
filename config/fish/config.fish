if status is-interactive
    # Commands to run in interactive sessions can go here
end

starship init fish | source

# Add ~/.local/bin to PATH for user-installed binaries
set --export PATH $HOME/.local/bin $PATH

# bun
set --export BUN_INSTALL "$HOME/.bun"
set --export PATH $BUN_INSTALL/bin $PATH

# starhsip 
set --export STARSHIP_CONFIG $HOME/.config/starship/starship.toml
