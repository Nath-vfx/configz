# Configz Fish completion

# Helper function to get available modules
function __configz_modules
    if command -v configz >/dev/null 2>&1
        configz list --json 2>/dev/null | string match -r '"id":\s*"([^"]*)"' | string replace -r '.*"([^"]*)".*' '$1'
    end
end

# Helper function to get installed modules
function __configz_installed_modules
    if command -v configz >/dev/null 2>&1
        configz status --installed --json 2>/dev/null | string match -r '"id":\s*"([^"]*)"' | string replace -r '.*"([^"]*)".*' '$1'
    end
end

# Helper function to get uninstalled modules
function __configz_uninstalled_modules
    if command -v configz >/dev/null 2>&1
        configz status --uninstalled --json 2>/dev/null | string match -r '"id":\s*"([^"]*)"' | string replace -r '.*"([^"]*)".*' '$1'
    end
end

# Main completion
complete -c configz -f

# Global options
complete -c configz -s h -l help -d "Show help message"
complete -c configz -s V -l version -d "Show version information"
complete -c configz -s v -l verbose -d "Enable verbose output"
complete -c configz -s q -l quiet -d "Suppress non-error output"
complete -c configz -s n -l dry-run -d "Show what would be done without executing"
complete -c configz -l no-backup -d "Skip automatic backups"
complete -c configz -l no-symlink -d "Use copy instead of symlinks"
complete -c configz -s f -l force -d "Force operations without confirmation"
complete -c configz -l config-dir -d "Use custom config directory" -r

# Commands
complete -c configz -n '__fish_use_subcommand' -a 'install' -d 'Install configuration modules'
complete -c configz -n '__fish_use_subcommand' -a 'list' -d 'List available modules'
complete -c configz -n '__fish_use_subcommand' -a 'status' -d 'Show installation status'
complete -c configz -n '__fish_use_subcommand' -a 'remove' -d 'Remove installed modules'
complete -c configz -n '__fish_use_subcommand' -a 'backup' -d 'Backup current configurations'
complete -c configz -n '__fish_use_subcommand' -a 'restore' -d 'Restore from backup'
complete -c configz -n '__fish_use_subcommand' -a 'search' -d 'Search for modules'
complete -c configz -n '__fish_use_subcommand' -a 'update' -d 'Update installed modules'
complete -c configz -n '__fish_use_subcommand' -a 'init' -d 'Create a new module template'
complete -c configz -n '__fish_use_subcommand' -a 'info' -d 'Show detailed module information'
complete -c configz -n '__fish_use_subcommand' -a 'doctor' -d 'Check system health and dependencies'

# install command
complete -c configz -n '__fish_seen_subcommand_from install' -s h -l help -d "Show help for install command"
complete -c configz -n '__fish_seen_subcommand_from install' -s a -l all -d "Install all available modules"
complete -c configz -n '__fish_seen_subcommand_from install' -s i -l interactive -d "Interactive selection mode"
complete -c configz -n '__fish_seen_subcommand_from install' -s f -l force -d "Force installation (overwrite existing)"
complete -c configz -n '__fish_seen_subcommand_from install' -l no-backup -d "Skip automatic backups"
complete -c configz -n '__fish_seen_subcommand_from install' -l no-symlink -d "Use copy instead of symlinks"
complete -c configz -n '__fish_seen_subcommand_from install' -l no-deps -d "Skip dependency checks"
complete -c configz -n '__fish_seen_subcommand_from install' -l dry-run -d "Show what would be installed without executing"
complete -c configz -n '__fish_seen_subcommand_from install' -a '(__configz_modules)' -d "Module to install"

# list command
complete -c configz -n '__fish_seen_subcommand_from list' -s h -l help -d "Show help for list command"
complete -c configz -n '__fish_seen_subcommand_from list' -s a -l all -d "Show all modules (default)"
complete -c configz -n '__fish_seen_subcommand_from list' -s i -l installed -d "Show only installed modules"
complete -c configz -n '__fish_seen_subcommand_from list' -s u -l uninstalled -d "Show only uninstalled modules"
complete -c configz -n '__fish_seen_subcommand_from list' -s l -l long -d "Show detailed information"
complete -c configz -n '__fish_seen_subcommand_from list' -l json -d "Output in JSON format"
complete -c configz -n '__fish_seen_subcommand_from list' -l no-color -d "Disable colored output"

# status command
complete -c configz -n '__fish_seen_subcommand_from status' -s h -l help -d "Show help for status command"
complete -c configz -n '__fish_seen_subcommand_from status' -s a -l all -d "Show all modules (default)"
complete -c configz -n '__fish_seen_subcommand_from status' -s i -l installed -d "Show only installed modules"
complete -c configz -n '__fish_seen_subcommand_from status' -s u -l uninstalled -d "Show only uninstalled modules"
complete -c configz -n '__fish_seen_subcommand_from status' -s d -l detailed -d "Show detailed status information"
complete -c configz -n '__fish_seen_subcommand_from status' -l json -d "Output in JSON format"
complete -c configz -n '__fish_seen_subcommand_from status' -l no-color -d "Disable colored output"
complete -c configz -n '__fish_seen_subcommand_from status' -a '(__configz_modules)' -d "Module to check"

# remove command
complete -c configz -n '__fish_seen_subcommand_from remove' -s h -l help -d "Show help for remove command"
complete -c configz -n '__fish_seen_subcommand_from remove' -s f -l force -d "Force removal without confirmation"
complete -c configz -n '__fish_seen_subcommand_from remove' -l no-backup -d "Skip automatic backups before removal"
complete -c configz -n '__fish_seen_subcommand_from remove' -l no-symlink -d "Assume copy mode instead of symlinks"
complete -c configz -n '__fish_seen_subcommand_from remove' -l clean -d "Remove backup files as well"
complete -c configz -n '__fish_seen_subcommand_from remove' -l dry-run -d "Show what would be removed without executing"
complete -c configz -n '__fish_seen_subcommand_from remove' -a '(__configz_installed_modules)' -d "Module to remove"

# backup command
complete -c configz -n '__fish_seen_subcommand_from backup' -s h -l help -d "Show help for backup command"
complete -c configz -n '__fish_seen_subcommand_from backup' -s a -l all -d "Backup all installed modules"
complete -c configz -n '__fish_seen_subcommand_from backup' -l dry-run -d "Show what would be backed up without executing"
complete -c configz -n '__fish_seen_subcommand_from backup' -a '(__configz_installed_modules)' -d "Module to backup"

# restore command
complete -c configz -n '__fish_seen_subcommand_from restore' -s h -l help -d "Show help for restore command"
complete -c configz -n '__fish_seen_subcommand_from restore' -s f -l force -d "Force restoration without confirmation"
complete -c configz -n '__fish_seen_subcommand_from restore' -l dry-run -d "Show what would be restored without executing"
complete -c configz -n '__fish_seen_subcommand_from restore' -a '(__configz_modules)' -d "Module to restore"

# search command
complete -c configz -n '__fish_seen_subcommand_from search' -s h -l help -d "Show help for search command"
complete -c configz -n '__fish_seen_subcommand_from search' -l json -d "Output in JSON format"
complete -c configz -n '__fish_seen_subcommand_from search' -l no-color -d "Disable colored output"

# update command
complete -c configz -n '__fish_seen_subcommand_from update' -s h -l help -d "Show help for update command"
complete -c configz -n '__fish_seen_subcommand_from update' -s a -l all -d "Update all installed modules"
complete -c configz -n '__fish_seen_subcommand_from update' -s f -l force -d "Force update without confirmation"
complete -c configz -n '__fish_seen_subcommand_from update' -l no-backup -d "Skip automatic backups"
complete -c configz -n '__fish_seen_subcommand_from update' -l dry-run -d "Show what would be updated without executing"
complete -c configz -n '__fish_seen_subcommand_from update' -a '(__configz_installed_modules)' -d "Module to update"

# init command
complete -c configz -n '__fish_seen_subcommand_from init' -s h -l help -d "Show help for init command"
complete -c configz -n '__fish_seen_subcommand_from init' -l template -d "Use a specific template" -a "basic advanced"

# info command
complete -c configz -n '__fish_seen_subcommand_from info' -s h -l help -d "Show help for info command"
complete -c configz -n '__fish_seen_subcommand_from info' -l json -d "Output in JSON format"
complete -c configz -n '__fish_seen_subcommand_from info' -l no-color -d "Disable colored output"
complete -c configz -n '__fish_seen_subcommand_from info' -l files -d "Show detailed file listing"
complete -c configz -n '__fish_seen_subcommand_from info' -l deps -d "Show dependency information"
complete -c configz -n '__fish_seen_subcommand_from info' -l all -d "Show all available information"
complete -c configz -n '__fish_seen_subcommand_from info' -a '(__configz_modules)' -d "Module to show info about"

# doctor command
complete -c configz -n '__fish_seen_subcommand_from doctor' -s h -l help -d "Show help for doctor command"
complete -c configz -n '__fish_seen_subcommand_from doctor' -l json -d "Output in JSON format"
complete -c configz -n '__fish_seen_subcommand_from doctor' -l no-color -d "Disable colored output"
complete -c configz -n '__fish_seen_subcommand_from doctor' -l fix -d "Attempt to fix issues automatically"
