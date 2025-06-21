#!/usr/bin/env bash

# Configz - Installation Script
# Interactive configuration deployment tool
# Version: 2.0 (Simplified)

# set -e

# =============================================================================
# CONFIGURATION AND SETUP
# =============================================================================

# Get script directory and project root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$SCRIPT_DIR"

# Configuration paths
CONFIG_SOURCE_DIR="$PROJECT_ROOT/config"
TARGET_BASE_DIR="$HOME/.config"

# Installation mode
DRY_RUN=${DRY_RUN:-0}
NO_BACKUP=${NO_BACKUP:-0}

# =============================================================================
# COLORS AND LOGGING
# =============================================================================

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# =============================================================================
# UTILITY FUNCTIONS
# =============================================================================

# Create directory if it doesn't exist
ensure_directory() {
    local dir="$1"
    if [[ ! -d "$dir" ]]; then
        mkdir -p "$dir"
    fi
}

# Create backup of a file
backup_file() {
    local file="$1"
    if [[ $NO_BACKUP -eq 1 ]]; then
        log_info "Backup désactivé pour: $file"
        return 0
    fi
    if [[ -f "$file" ]]; then
        local backup_file="${file}.backup.$(date +%Y%m%d_%H%M%S)"
        cp "$file" "$backup_file"
        log_info "Backup créé: $backup_file"
    fi
}

# Create backup of a directory
backup_directory() {
    local dir="$1"
    if [[ $NO_BACKUP -eq 1 ]]; then
        log_info "Backup désactivé pour le dossier: $dir"
        return 0
    fi
    if [[ -d "$dir" && "$(ls -A "$dir")" ]]; then
        local backup_dir="${dir}.backup.$(date +%Y%m%d_%H%M%S)"
        cp -r "$dir" "$backup_dir"
        log_info "Backup du dossier créé: $backup_dir"
    fi
}

# =============================================================================
# TOOL MANAGEMENT
# =============================================================================

# Dynamic module selection state
declare -A MODULE_SELECTION
declare -a AVAILABLE_MODULES
declare -A MODULE_INFO

# Parse TOML configuration for a module
parse_module_config() {
    local module_id="$1"
    local config_file="$CONFIG_SOURCE_DIR/$module_id/configz.toml"

    if [[ ! -f "$config_file" ]]; then
        log_warning "No configz.toml found for module: $module_id"
        return 1
    fi

    # Parse TOML using yq
    local name=$(yq eval '.module.name' "$config_file" 2>/dev/null || echo "$module_id")
    local desc=$(yq eval '.module.description' "$config_file" 2>/dev/null || echo "Configuration module")
    local icon=$(yq eval '.module.icon' "$config_file" 2>/dev/null || echo "📦")
    local target=$(yq eval '.paths.target' "$config_file" 2>/dev/null || echo "$module_id")
    local install_type=$(yq eval '.installation.type' "$config_file" 2>/dev/null || echo "copy")

    MODULE_INFO["${module_id}_name"]="$icon $name"
    MODULE_INFO["${module_id}_desc"]="$desc"
    MODULE_INFO["${module_id}_target"]="$target"
    MODULE_INFO["${module_id}_type"]="$install_type"
    MODULE_INFO["${module_id}_config"]="$config_file"
}

# Initialize module discovery
init_module_discovery() {
    if [[ ! -d "$CONFIG_SOURCE_DIR" ]]; then
        log_error "Configuration directory not found: $CONFIG_SOURCE_DIR"
        exit 1
    fi

    # Auto-discover modules by scanning config directory
    for module_dir in "$CONFIG_SOURCE_DIR"/*; do
        if [[ -d "$module_dir" ]]; then
            local module_id=$(basename "$module_dir")

            # Skip if no configz.toml exists, but try to parse anyway
            if parse_module_config "$module_id"; then
                AVAILABLE_MODULES+=("$module_id")
                MODULE_SELECTION["$module_id"]=0
                log_info "Discovered module: $module_id"
            fi
        fi
    done

    if [[ ${#AVAILABLE_MODULES[@]} -eq 0 ]]; then
        log_error "No modules found in $CONFIG_SOURCE_DIR"
        exit 1
    fi
}

# Show header
show_header() {
    clear
    echo -e "${BOLD}${CYAN}╔══════════════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BOLD}${CYAN}║                                                                              ║${NC}"
    echo -e "${BOLD}${CYAN}║                          🎛️  CONFIGZ INSTALLER                             ║${NC}"
    echo -e "${BOLD}${CYAN}║                                                                              ║${NC}"
    echo -e "${BOLD}${CYAN}║              Sélectionnez les configurations à installer                    ║${NC}"
    echo -e "${BOLD}${CYAN}║                                                                              ║${NC}"
    echo -e "${BOLD}${CYAN}╚══════════════════════════════════════════════════════════════════════════════╝${NC}"
    echo
}

# Show interactive menu
show_menu() {
    show_header

    echo -e "${BOLD}📦 Configurations disponibles :${NC}"
    echo

    local index=1
    for module_id in "${AVAILABLE_MODULES[@]}"; do
        local module_name="${MODULE_INFO[${module_id}_name]}"
        local module_desc="${MODULE_INFO[${module_id}_desc]}"
        local target_path="${MODULE_INFO[${module_id}_target]}"

        local checkbox_icon status_text
        if [[ ${MODULE_SELECTION["$module_id"]} -eq 1 ]]; then
            checkbox_icon="${GREEN}☑${NC}"
            status_text="${GREEN}Sélectionné${NC}"
        else
            checkbox_icon="${RED}☐${NC}"
            status_text="${RED}Non sélectionné${NC}"
        fi

        # Check if already installed
        local install_status=""
        if [[ -e "$TARGET_BASE_DIR/$target_path" ]]; then
            install_status=" ${YELLOW}(Installé)${NC}"
        fi

        echo -e "  $checkbox_icon ${BOLD}$index.${NC} $module_name"
        echo -e "     ${DIM}$module_desc${NC}"
        echo -e "     ${BLUE}└─${NC} Target: ${BOLD}~/.config/$target_path${NC}$install_status"
        echo -e "     Status: $status_text"
        echo

        ((index++))
    done

    echo -e "${BOLD}🎮 Actions disponibles :${NC}"
    echo -e "  ${YELLOW}1-${#AVAILABLE_TOOLS[@]}${NC} - Basculer la sélection d'un outil"
    echo -e "  ${YELLOW}a${NC} - Tout sélectionner"
    echo -e "  ${YELLOW}n${NC} - Tout désélectionner"
    echo -e "  ${GREEN}i${NC} - Installer les configurations sélectionnées"
    echo -e "  ${BLUE}s${NC} - Afficher le statut"
    echo -e "  ${RED}q${NC} - Quitter"
    echo
    echo -e "${BOLD}Votre choix :${NC} "
}

# Toggle tool selection
toggle_selection() {
    local selection="$1"

    # Check if it's a valid number
    if [[ "$selection" =~ ^[0-9]+$ ]] && [ "$selection" -ge 1 ] && [ "$selection" -le "${#AVAILABLE_MODULES[@]}" ]; then
        local module_id="${AVAILABLE_MODULES[$((selection - 1))]}"

        if [[ ${MODULE_SELECTION["$module_id"]} -eq 0 ]]; then
            MODULE_SELECTION["$module_id"]=1
            echo -e "${GREEN}✓ ${MODULE_INFO[${module_id}_name]} sélectionné${NC}"
        else
            MODULE_SELECTION["$module_id"]=0
            echo -e "${YELLOW}○ ${MODULE_INFO[${module_id}_name]} désélectionné${NC}"
        fi
        sleep 1
        return 0
    fi
    return 1
}

# Select all modules
select_all() {
    for module in "${AVAILABLE_MODULES[@]}"; do
        MODULE_SELECTION["$module"]=1
    done
    echo -e "${GREEN}✓ Tous les modules sélectionnés${NC}"
    sleep 1
}

# Deselect all modules
select_none() {
    for module in "${AVAILABLE_MODULES[@]}"; do
        MODULE_SELECTION["$module"]=0
    done
    echo -e "${YELLOW}○ Tous les modules désélectionnés${NC}"
    sleep 1
}

# Get selected tools
get_selected_modules() {
    local selected=()

    for module in "${AVAILABLE_MODULES[@]}"; do
        if [[ ${MODULE_SELECTION["$module"]} -eq 1 ]]; then
            selected+=("$module")
        fi
    done

    printf '%s\n' "${selected[@]}"
}

# Show status
show_status() {
    clear
    echo -e "${BOLD}${CYAN}📊 Status des Configurations${NC}"
    echo "════════════════════════════════"
    echo

    local selected_count=0
    local installed_count=0

    for module_id in "${AVAILABLE_MODULES[@]}"; do
        local module_name="${MODULE_INFO[${module_id}_name]}"
        local target_path="${MODULE_INFO[${module_id}_target]}"

        local selection_status install_status

        if [[ ${MODULE_SELECTION["$module_id"]} -eq 1 ]]; then
            selection_status="${GREEN}Sélectionné${NC}"
            ((selected_count++))
        else
            selection_status="${DIM}Non sélectionné${NC}"
        fi

        if [[ -e "$TARGET_BASE_DIR/$target_path" ]]; then
            install_status="${GREEN}Installé${NC}"
        else
            install_status="${DIM}Non installé${NC}"
        fi

        echo -e "  ${BOLD}$module_name${NC} - $selection_status ($install_status)"
        echo -e "  Target: ${DIM}~/.config/$target_path${NC}"
        echo
    done

    echo -e "${BOLD}Résumé :${NC}"
    echo "  Total d'outils: ${#AVAILABLE_TOOLS[@]}"
    echo "  Sélectionnés: $selected_count"
    echo "  Installés: $installed_count"
    echo

    echo -e "Appuyez sur ${BOLD}Entrée${NC} pour continuer..."
    read -r
}

# =============================================================================
# INSTALLATION FUNCTIONS
# =============================================================================

# Install Fish Shell
install_fish() {
    log_info "Installation de Fish Shell..."
    local target_dir="$TARGET_BASE_DIR/fish"

    ensure_directory "$target_dir"

    if [[ -f "$target_dir/config.fish" ]]; then
        backup_file "$target_dir/config.fish"
    fi

    cp "$PROJECT_ROOT/config/fish/config.fish" "$target_dir/config.fish"
    log_success "Fish Shell configuré ✓"
}

# Install Ghostty Terminal
install_ghostty() {
    log_info "Installation de Ghostty Terminal..."
    local target_dir="$TARGET_BASE_DIR/ghostty"

    ensure_directory "$target_dir"
    ensure_directory "$target_dir/theme"

    if [[ -d "$target_dir" && "$(ls -A "$target_dir")" ]]; then
        backup_directory "$target_dir"
    fi

    cp "$PROJECT_ROOT/config/ghostty/config" "$target_dir/config"
    cp "$PROJECT_ROOT/config/ghostty/theme/main" "$target_dir/theme/main"
    log_success "Ghostty Terminal configuré ✓"
}

# Install Starship Prompt
install_starship() {
    log_info "Installation de Starship Prompt..."
    local target_dir="$TARGET_BASE_DIR/starship"

    ensure_directory "$target_dir"

    if [[ -f "$target_dir/starship.toml" ]]; then
        backup_file "$target_dir/starship.toml"
    fi

    cp "$PROJECT_ROOT/config/starship/starship.toml" "$target_dir/starship.toml"
    log_success "Starship Prompt configuré ✓"
}

# Generic module installer using TOML configuration
install_module() {
    local module_id="$1"
    local config_file="${MODULE_INFO[${module_id}_config]}"
    local install_type="${MODULE_INFO[${module_id}_type]}"
    local target_path="${MODULE_INFO[${module_id}_target]}"
    local full_target="$TARGET_BASE_DIR/$target_path"

    log_info "Installation de ${MODULE_INFO[${module_id}_name]}"

    # Create target directory
    ensure_directory "$full_target"

    # Handle backup based on TOML config
    local backup_strategy=$(yq eval '.backup.strategy' "$config_file" 2>/dev/null || echo "auto")
    if [[ "$backup_strategy" != "none" && $NO_BACKUP -eq 0 ]]; then
        if [[ -d "$full_target" && "$(ls -A "$full_target" 2>/dev/null)" ]]; then
            backup_directory "$full_target"
        fi
    fi

    # Get sources from TOML
    local sources_count=$(yq eval '.paths.sources | length' "$config_file" 2>/dev/null || echo "0")
    if [[ "$sources_count" -gt 0 ]]; then
        for ((i=0; i<sources_count; i++)); do
            local source=$(yq eval ".paths.sources[$i]" "$config_file")
            local source_path="$CONFIG_SOURCE_DIR/$module_id/$source"

            if [[ -e "$source_path" ]]; then
                case "$install_type" in
                    "copy")
                        cp -r "$source_path" "$full_target/"
                        ;;
                    "symlink")
                        ln -sf "$source_path" "$full_target/"
                        ;;
                    *)
                        log_error "Type d'installation non supporté: $install_type"
                        return 1
                        ;;
                esac
            else
                log_warning "Source non trouvée: $source_path"
            fi
        done
    else
        # Fallback: copy all non-toml files
        find "$CONFIG_SOURCE_DIR/$module_id" -type f ! -name "configz.toml" -exec cp {} "$full_target/" \;
    fi

    log_success "${MODULE_INFO[${module_id}_name]} configuré ✓"
}

# Show installation confirmation
show_installation_confirmation() {
    local selected_tools=("$@")

    clear
    echo -e "${BOLD}${YELLOW}⚠️  CONFIRMATION D'INSTALLATION${NC}"
    echo "══════════════════════════════════════"
    echo
    echo -e "${BOLD}Vous êtes sur le point d'installer ${#selected_tools[@]} configuration(s) :${NC}"
    echo

    for tool_id in "${selected_tools[@]}"; do
        local tool_name="${MODULE_INFO[${tool_id}_name]}"
        local tool_desc="${MODULE_INFO[${tool_id}_desc]}"
        local target_path="${MODULE_INFO[${tool_id}_target]}"
        local full_target="$TARGET_BASE_DIR/$target_path"

        echo -e "  ${GREEN}✓${NC} ${BOLD}$tool_name${NC}"
        echo -e "     ${DIM}$tool_desc${NC}"
        echo -e "     ${BLUE}└─${NC} Installation vers: ${BOLD}~/$target_path${NC}"

        # Check if target already exists
        if [[ -e "$full_target" ]]; then
            echo -e "     ${YELLOW}⚠️  Remplacera la configuration existante${NC}"
            echo -e "     ${DIM}└─ Un backup sera créé automatiquement${NC}"
        else
            echo -e "     ${GREEN}✨ Nouvelle installation${NC}"
        fi
        echo
    done

    echo -e "${BOLD}📋 Actions qui seront effectuées :${NC}"
    echo "  • Création des dossiers nécessaires"
    echo "  • Backup automatique des configurations existantes"
    echo "  • Copie des nouvelles configurations"
    echo "  • Vérification de l'installation"
    echo

    echo -e "${BOLD}${CYAN}❓ Voulez-vous continuer avec cette installation ?${NC}"
    echo -e "   ${GREEN}y/Y${NC} - Oui, installer maintenant"
    echo -e "   ${RED}n/N${NC} - Non, retourner au menu"
    echo -e "   ${BLUE}d/D${NC} - Afficher plus de détails"
    echo
    echo -n "Votre choix [y/n/d]: "
}

# Run installation process
run_installation() {
    local selected_tools
    mapfile -t selected_tools < <(get_selected_modules)

    if [[ ${#selected_tools[@]} -eq 0 ]]; then
        log_warning "Aucune configuration sélectionnée !"
        echo -e "\nAppuyez sur ${BOLD}Entrée${NC} pour continuer..."
        read -r
        return
    fi

    # Show confirmation dialog
    while true; do
        show_installation_confirmation "${selected_tools[@]}"
        read -r confirmation

        case "$confirmation" in
            y|Y|yes|YES|oui|OUI)
                break
                ;;
            n|N|no|NO|non|NON)
                echo -e "\n${YELLOW}Installation annulée.${NC}"
                sleep 1
                return
                ;;
            d|D|detail|DETAIL)
                show_installation_details "${selected_tools[@]}"
                ;;
            *)
                echo -e "\n${RED}Réponse invalide. Utilisez y/n/d${NC}"
                sleep 2
                ;;
        esac
    done

    clear
    echo -e "${BOLD}${CYAN}🚀 Installation en cours...${NC}"
    echo
    echo "Outils sélectionnés: ${selected_tools[*]}"
    echo

    # Ensure target directory exists
    ensure_directory "$TARGET_BASE_DIR"

    # Install each selected tool
    local success_count=0
    local failed_tools=()

    for tool_id in "${selected_tools[@]}"; do
        echo -e "${BOLD}[${tool_id}]${NC} Installation..."

        if install_module "$tool_id"; then
            ((success_count++))
        else
            failed_tools+=("$tool_id")
        fi
        echo
    done

    # Show summary
    echo -e "${BOLD}${GREEN}✨ Installation terminée !${NC}"
    echo "═══════════════════════════════"
    echo "Réussis: $success_count/${#selected_tools[@]}"

    if [[ ${#failed_tools[@]} -gt 0 ]]; then
        echo "Échecs: ${failed_tools[*]}"
    fi
    echo

    # Show post-installation notes
    show_post_install_notes "${selected_tools[@]}"

    # Only wait for input if running interactively
    if [[ -t 0 ]]; then
        echo -e "Appuyez sur ${BOLD}Entrée${NC} pour continuer..."
        read -r
    fi
}

# Show installation details
show_installation_details() {
    local selected_tools=("$@")

    clear
    echo -e "${BOLD}${BLUE}📋 DÉTAILS DE L'INSTALLATION${NC}"
    echo "══════════════════════════════════════"
    echo

    for tool_id in "${selected_tools[@]}"; do
        local tool_name="${MODULE_INFO[${tool_id}_name]}"
        local source_path="$CONFIG_SOURCE_DIR/$tool_id"
        local target_path="${MODULE_INFO[${tool_id}_target]}"
        local full_source="$source_path"
        local full_target="$TARGET_BASE_DIR/$target_path"

        echo -e "${BOLD}$tool_name${NC}"
        echo "────────────────────────────────"
        echo -e "Source      : ${DIM}$full_source${NC}"
        echo -e "Destination : ${DIM}$full_target${NC}"

        # Show source files
        if [[ -d "$full_source" ]]; then
            echo -e "Fichiers    : ${DIM}"
            find "$full_source" -type f -printf "              %P\n" 2>/dev/null | head -5
            local file_count=$(find "$full_source" -type f 2>/dev/null | wc -l)
            if [[ $file_count -gt 5 ]]; then
                echo -e "              ... et $((file_count - 5)) autres fichiers"
            fi
            echo -e "${NC}"
        fi

        # Check target status
        if [[ -e "$full_target" ]]; then
            local mod_time=$(stat -c %Y "$full_target" 2>/dev/null || echo "0")
            local mod_date=$(date -d "@$mod_time" "+%Y-%m-%d %H:%M" 2>/dev/null || echo "inconnu")
            echo -e "Status      : ${YELLOW}Existe déjà (modifié le $mod_date)${NC}"
            echo -e "Action      : ${YELLOW}Backup + Remplacement${NC}"
        else
            echo -e "Status      : ${GREEN}Nouveau${NC}"
            echo -e "Action      : ${GREEN}Installation${NC}"
        fi
        echo
    done

    echo -e "${BOLD}Appuyez sur ${BOLD}Entrée${NC} pour revenir à la confirmation..."
    read -r
}

# Show post-installation notes
show_post_install_notes() {
    local installed_tools=("$@")

    echo -e "${BOLD}📝 Notes post-installation :${NC}"
    echo

    for tool in "${installed_tools[@]}"; do
        case "$tool" in
            "fish")
                echo -e "  ${BLUE}🐟 Fish Shell:${NC}"
                echo -e "     • Redémarrez votre terminal ou exécutez: ${BOLD}exec fish${NC}"
                echo
                ;;
            "ghostty")
                echo -e "  ${BLUE}👻 Ghostty Terminal:${NC}"
                echo -e "     • Redémarrez Ghostty pour appliquer la configuration"
                echo
                ;;
            "starship")
                echo -e "  ${BLUE}⭐ Starship Prompt:${NC}"
                echo -e "     • Assurez-vous que Starship est installé"
                echo -e "     • Ajoutez dans votre shell: ${BOLD}eval \"\$(starship init bash)\"${NC}"
                echo
                ;;
        esac
    done

    echo -e "${DIM}💾 Les configurations existantes ont été sauvegardées.${NC}"
    echo
}

# =============================================================================
# MAIN FUNCTION
# =============================================================================

# Main function
main() {
    parse_args "$@"

    log_info "Démarrage de Configz Installer..."
    log_info "Répertoire source: $PROJECT_ROOT"
    log_info "Répertoire cible: $TARGET_BASE_DIR"

    if [[ $NO_BACKUP -eq 1 ]]; then
        log_warning "Mode sans backup activé - aucune sauvegarde ne sera créée"
    fi

    if [[ $DRY_RUN -eq 1 ]]; then
        log_warning "Mode simulation activé - aucune modification ne sera effectuée"
    fi

    # Initialize module discovery
    init_module_discovery

    log_info "Modules disponibles: ${#AVAILABLE_MODULES[@]} (${AVAILABLE_MODULES[*]})"

    while true; do
        show_menu
        read -r choice

        case "$choice" in
            [1-9])
                if ! toggle_selection "$choice"; then
                    echo "Option invalide: $choice"
                    sleep 1
                fi
                ;;
            [1-9][0-9])
                if ! toggle_selection "$choice"; then
                    echo "Option invalide: $choice"
                    sleep 1
                fi
                ;;
            a|A)
                select_all
                ;;
            n|N)
                select_none
                ;;
            i|I)
                run_installation
                ;;
            s|S)
                show_status
                ;;
            q|Q)
                clear
                echo -e "${BOLD}${CYAN}👋 Au revoir !${NC}"
                echo -e "${DIM}Merci d'avoir utilisé Configz Installer${NC}"
                exit 0
                ;;
            "")
                # Empty input, just refresh
                ;;
            *)
                echo "Option invalide: '$choice'"
                echo "Utilisez 1-${#AVAILABLE_TOOLS[@]}, a, n, i, s, ou q"
                sleep 2
                ;;
        esac
    done
}

# Parse command line arguments
parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --no-backup)
                NO_BACKUP=1
                shift
                ;;
            --dry-run)
                DRY_RUN=1
                shift
                ;;
            -h|--help)
                show_help
                exit 0
                ;;
            *)
                echo "Option inconnue: $1"
                show_help
                exit 1
                ;;
        esac
    done
}

# Show help message
show_help() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  --no-backup    Désactive la création des archives de sauvegarde"
    echo "  --dry-run      Mode simulation (affiche les actions sans les exécuter)"
    echo "  -h, --help     Affiche cette aide"
    echo ""
    echo "Exemples:"
    echo "  $0                # Installation normale avec backup"
    echo "  $0 --no-backup   # Installation sans backup"
    echo "  $0 --dry-run     # Simulation des actions"
}



# Launch the script
main "$@"
