#!/bin/bash

# Configz - Installation Script
# Interactive configuration deployment tool
# Version: 2.0 (Simplified)

set -e

# =============================================================================
# CONFIGURATION AND SETUP
# =============================================================================

# Get script directory and project root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$SCRIPT_DIR"

# Configuration paths
TOOLS_CONFIG="$PROJECT_ROOT/lib/tools.conf"
CONFIG_SOURCE_DIR="$PROJECT_ROOT/config"
TARGET_BASE_DIR="$HOME/.config"

# Installation mode
DRY_RUN=${DRY_RUN:-0}

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
    if [[ -f "$file" ]]; then
        local backup_file="${file}.backup.$(date +%Y%m%d_%H%M%S)"
        cp "$file" "$backup_file"
        log_info "Backup créé: $backup_file"
    fi
}

# Create backup of a directory
backup_directory() {
    local dir="$1"
    if [[ -d "$dir" && "$(ls -A "$dir")" ]]; then
        local backup_dir="${dir}.backup.$(date +%Y%m%d_%H%M%S)"
        cp -r "$dir" "$backup_dir"
        log_info "Backup du dossier créé: $backup_dir"
    fi
}

# =============================================================================
# TOOL MANAGEMENT
# =============================================================================

# Dynamic tool selection state
declare -A TOOL_SELECTION
declare -a AVAILABLE_TOOLS
declare -A TOOL_INFO

# Initialize tool selection
init_tool_selection() {
    if [[ ! -f "$TOOLS_CONFIG" ]]; then
        log_error "Configuration file not found: $TOOLS_CONFIG"
        exit 1
    fi

    # Parse tools configuration
    while IFS='|' read -r tool_id tool_name tool_desc source_path target_path install_func; do
        # Skip comments and empty lines
        [[ "$tool_id" =~ ^[[:space:]]*# ]] && continue
        [[ -z "${tool_id// }" ]] && continue

        AVAILABLE_TOOLS+=("$tool_id")
        TOOL_SELECTION["$tool_id"]=0
        TOOL_INFO["${tool_id}_name"]="$tool_name"
        TOOL_INFO["${tool_id}_desc"]="$tool_desc"
        TOOL_INFO["${tool_id}_source"]="$source_path"
        TOOL_INFO["${tool_id}_target"]="$target_path"
        TOOL_INFO["${tool_id}_func"]="$install_func"
    done < "$TOOLS_CONFIG"

    if [[ ${#AVAILABLE_TOOLS[@]} -eq 0 ]]; then
        log_error "No tools found in configuration"
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
    for tool_id in "${AVAILABLE_TOOLS[@]}"; do
        local tool_name="${TOOL_INFO[${tool_id}_name]}"
        local tool_desc="${TOOL_INFO[${tool_id}_desc]}"
        local target_path="${TOOL_INFO[${tool_id}_target]}"

        local checkbox_icon status_text
        if [[ ${TOOL_SELECTION["$tool_id"]} -eq 1 ]]; then
            checkbox_icon="${GREEN}☑${NC}"
            status_text="${GREEN}Sélectionné${NC}"
        else
            checkbox_icon="${RED}☐${NC}"
            status_text="${DIM}Non sélectionné${NC}"
        fi

        # Check if already installed
        local install_status=""
        if [[ -e "$TARGET_BASE_DIR/$target_path" ]]; then
            install_status=" ${YELLOW}(Déjà installé)${NC}"
        fi

        echo -e "  $checkbox_icon ${YELLOW}$index.${NC} ${BOLD}$tool_name${NC}$install_status"
        echo -e "     ${DIM}$tool_desc${NC}"
        echo -e "     ${BLUE}└─${NC} Target: ${DIM}~/$target_path${NC}"
        echo -e "     ${DIM}Status: $status_text${NC}"
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
    if [[ "$selection" =~ ^[0-9]+$ ]] && [ "$selection" -ge 1 ] && [ "$selection" -le "${#AVAILABLE_TOOLS[@]}" ]; then
        local tool_id="${AVAILABLE_TOOLS[$((selection - 1))]}"

        if [[ ${TOOL_SELECTION["$tool_id"]} -eq 0 ]]; then
            TOOL_SELECTION["$tool_id"]=1
            echo -e "${GREEN}✓ ${TOOL_INFO[${tool_id}_name]} sélectionné${NC}"
        else
            TOOL_SELECTION["$tool_id"]=0
            echo -e "${YELLOW}○ ${TOOL_INFO[${tool_id}_name]} désélectionné${NC}"
        fi
        sleep 1
        return 0
    fi
    return 1
}

# Select all tools
select_all() {
    for tool in "${AVAILABLE_TOOLS[@]}"; do
        TOOL_SELECTION["$tool"]=1
    done
    echo -e "${GREEN}✓ Tous les outils sélectionnés${NC}"
    sleep 1
}

# Deselect all tools
select_none() {
    for tool in "${AVAILABLE_TOOLS[@]}"; do
        TOOL_SELECTION["$tool"]=0
    done
    echo -e "${YELLOW}○ Tous les outils désélectionnés${NC}"
    sleep 1
}

# Get selected tools
get_selected_tools() {
    local selected=()

    for tool in "${AVAILABLE_TOOLS[@]}"; do
        if [[ ${TOOL_SELECTION["$tool"]} -eq 1 ]]; then
            selected+=("$tool")
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

    for tool_id in "${AVAILABLE_TOOLS[@]}"; do
        local tool_name="${TOOL_INFO[${tool_id}_name]}"
        local target_path="${TOOL_INFO[${tool_id}_target]}"

        local selection_status install_status

        if [[ ${TOOL_SELECTION["$tool_id"]} -eq 1 ]]; then
            selection_status="${GREEN}Sélectionné${NC}"
            ((selected_count++))
        else
            selection_status="${DIM}Non sélectionné${NC}"
        fi

        if [[ -e "$TARGET_BASE_DIR/$target_path" ]]; then
            install_status="${GREEN}Installé${NC}"
            ((installed_count++))
        else
            install_status="${RED}Non installé${NC}"
        fi

        echo -e "${BOLD}$tool_name${NC}"
        echo -e "  Sélection: $selection_status"
        echo -e "  Installation: $install_status"
        echo -e "  Chemin: ${DIM}~/$target_path${NC}"
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

# Install a single tool
install_tool() {
    local tool_id="$1"
    local install_func="${TOOL_INFO[${tool_id}_func]}"

    # Check if install function exists and call it
    if command -v "$install_func" >/dev/null 2>&1; then
        "$install_func"
    else
        log_error "Fonction d'installation non trouvée: $install_func"
        return 1
    fi
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
        local tool_name="${TOOL_INFO[${tool_id}_name]}"
        local tool_desc="${TOOL_INFO[${tool_id}_desc]}"
        local target_path="${TOOL_INFO[${tool_id}_target]}"
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
    mapfile -t selected_tools < <(get_selected_tools)

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

        if install_tool "$tool_id"; then
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

    echo -e "Appuyez sur ${BOLD}Entrée${NC} pour continuer..."
    read -r
}

# Show installation details
show_installation_details() {
    local selected_tools=("$@")

    clear
    echo -e "${BOLD}${BLUE}📋 DÉTAILS DE L'INSTALLATION${NC}"
    echo "══════════════════════════════════════"
    echo

    for tool_id in "${selected_tools[@]}"; do
        local tool_name="${TOOL_INFO[${tool_id}_name]}"
        local source_path="${TOOL_INFO[${tool_id}_source]}"
        local target_path="${TOOL_INFO[${tool_id}_target]}"
        local full_source="$PROJECT_ROOT/$source_path"
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
    log_info "Démarrage de Configz Installer..."
    log_info "Répertoire source: $PROJECT_ROOT"
    log_info "Répertoire cible: $TARGET_BASE_DIR"

    # Initialize tool selection
    init_tool_selection

    log_info "Outils disponibles: ${#AVAILABLE_TOOLS[@]} (${AVAILABLE_TOOLS[*]})"

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

# Launch the script
main "$@"
