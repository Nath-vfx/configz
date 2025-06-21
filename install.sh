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

# Parse TOML configuration for a module (optional)
parse_module_config() {
    local module_id="$1"
    local config_file="$CONFIG_SOURCE_DIR/$module_id/configz.toml"

    # Default configuration based on folder name
    local name=$(echo "$module_id" | sed 's/_/ /g' | awk '{print toupper(substr($0,1,1)) tolower(substr($0,2))}')  # Capitalize first letter and replace underscores
    local desc="Configuration pour $name"
    local icon="📦"
    local target="$module_id"
    local install_type="copy"

    # Override with TOML if it exists
    if [[ -f "$config_file" ]]; then
        log_info "Using configz.toml for module: $module_id"
        name=$(yq eval '.module.name' "$config_file" 2>/dev/null || echo "$name")
        desc=$(yq eval '.module.description' "$config_file" 2>/dev/null || echo "$desc")
        icon=$(yq eval '.module.icon' "$config_file" 2>/dev/null || echo "$icon")
        target=$(yq eval '.paths.target' "$config_file" 2>/dev/null || echo "$target")
        install_type=$(yq eval '.installation.type' "$config_file" 2>/dev/null || echo "$install_type")
        MODULE_INFO["${module_id}_config"]="$config_file"
    else
        log_info "Using default configuration for module: $module_id"
        MODULE_INFO["${module_id}_config"]=""
    fi

    MODULE_INFO["${module_id}_name"]="$icon $name"
    MODULE_INFO["${module_id}_desc"]="$desc"
    MODULE_INFO["${module_id}_target"]="$target"
    MODULE_INFO["${module_id}_type"]="$install_type"
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

            # Always try to parse module config (TOML is optional)
            parse_module_config "$module_id"
            AVAILABLE_MODULES+=("$module_id")
            MODULE_SELECTION["$module_id"]=0
            log_info "Discovered module: $module_id"
        fi
    done

    if [[ ${#AVAILABLE_MODULES[@]} -eq 0 ]]; then
        log_error "No modules found in $CONFIG_SOURCE_DIR"
        exit 1
    fi
}

# Show header for selection phase
show_selection_header() {
    clear
    echo -e "${BOLD}${CYAN}╔══════════════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BOLD}${CYAN}║                                                                              ║${NC}"
    echo -e "${BOLD}${CYAN}║                     🎛️  PHASE 1: SÉLECTION DES MODULES                     ║${NC}"
    echo -e "${BOLD}${CYAN}║                                                                              ║${NC}"
    echo -e "${BOLD}${CYAN}║               Utilisez ↑↓ pour naviguer, ESPACE pour sélectionner          ║${NC}"
    echo -e "${BOLD}${CYAN}║                                                                              ║${NC}"
    echo -e "${BOLD}${CYAN}╚══════════════════════════════════════════════════════════════════════════════╝${NC}"
    echo
}

# Global variables for checkbox interface
CURRENT_ITEM=0
ITEMS_PER_PAGE=10

# Show checkbox interface
show_checkbox_interface() {
    show_selection_header

    local total_items=${#AVAILABLE_MODULES[@]}
    local start_index=$((CURRENT_ITEM - CURRENT_ITEM % ITEMS_PER_PAGE))
    local end_index=$((start_index + ITEMS_PER_PAGE - 1))
    if [[ $end_index -ge $total_items ]]; then
        end_index=$((total_items - 1))
    fi

    echo -e "${BOLD}📦 Configurations disponibles :${NC}"
    echo

    # Display items
    for ((i=start_index; i<=end_index; i++)); do
        local module_id="${AVAILABLE_MODULES[$i]}"
        local module_name="${MODULE_INFO[${module_id}_name]}"
        local module_desc="${MODULE_INFO[${module_id}_desc]}"
        local target_path="${MODULE_INFO[${module_id}_target]}"

        # Checkbox state
        local checkbox=""
        if [[ ${MODULE_SELECTION["$module_id"]} -eq 1 ]]; then
            checkbox="${GREEN}[✓]${NC}"
        else
            checkbox="${DIM}[ ]${NC}"
        fi

        # Selection highlight
        local prefix=""
        local suffix=""
        if [[ $i -eq $CURRENT_ITEM ]]; then
            prefix="${CYAN}▶ ${NC}"
            checkbox="${BOLD}${checkbox}${NC}"
        else
            prefix="  "
        fi

        # Installation status
        local install_status=""
        if [[ -e "$TARGET_BASE_DIR/$target_path" ]]; then
            install_status=" ${YELLOW}●${NC}"
        fi

        echo -e "${prefix}${checkbox} ${BOLD}${module_name}${NC}${install_status}"
        echo -e "    ${DIM}${module_desc}${NC}"
        echo -e "    ${BLUE}→${NC} ~/.config/${target_path}"
        echo
    done

    # Show navigation info
    local selected_count=0
    for module in "${AVAILABLE_MODULES[@]}"; do
        if [[ ${MODULE_SELECTION["$module"]} -eq 1 ]]; then
            ((selected_count++))
        fi
    done

    echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BOLD}📊 Sélectionnés: ${GREEN}$selected_count${NC}/$total_items  ${BOLD}Page: ${CYAN}$((start_index/ITEMS_PER_PAGE + 1))${NC}/$((($total_items-1)/ITEMS_PER_PAGE + 1))${NC}"
    echo
    echo -e "${BOLD}🎮 Contrôles :${NC}"
    echo -e "  ${YELLOW}↑/k${NC} Haut    ${YELLOW}↓/j${NC} Bas    ${YELLOW}ESPACE${NC} Sélectionner    ${YELLOW}a${NC} Tout    ${YELLOW}n${NC} Rien"
    echo -e "  ${GREEN}ENTRÉE${NC} Continuer    ${RED}q/ESC${NC} Quitter"
    echo
    echo -e "${DIM}Légende: ● = Déjà installé${NC}"
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
}

# Deselect all modules
select_none() {
    for module in "${AVAILABLE_MODULES[@]}"; do
        MODULE_SELECTION["$module"]=0
    done
    echo -e "${YELLOW}○ Tous les modules désélectionnés${NC}"
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

# Generic module installer using TOML configuration or defaults
install_module() {
    local module_id="$1"
    local config_file="${MODULE_INFO[${module_id}_config]}"
    local install_type="${MODULE_INFO[${module_id}_type]}"
    local target_path="${MODULE_INFO[${module_id}_target]}"
    local full_target="$TARGET_BASE_DIR/$target_path"

    log_info "Installation de ${MODULE_INFO[${module_id}_name]}"

    # Create target directory
    ensure_directory "$full_target"

    # Handle backup
    local backup_strategy="auto"
    if [[ -n "$config_file" ]]; then
        backup_strategy=$(yq eval '.backup.strategy' "$config_file" 2>/dev/null || echo "auto")
    fi

    if [[ "$backup_strategy" != "none" && $NO_BACKUP -eq 0 ]]; then
        if [[ -d "$full_target" && "$(ls -A "$full_target" 2>/dev/null)" ]]; then
            backup_directory "$full_target"
        fi
    fi

    # Install files
    if [[ -n "$config_file" ]]; then
        # Use TOML configuration for sources
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
            # TOML exists but no sources defined, use default behavior
            install_module_default "$module_id" "$full_target"
        fi
    else
        # No TOML file, use default installation
        install_module_default "$module_id" "$full_target"
    fi

    log_success "${MODULE_INFO[${module_id}_name]} configuré ✓"
}

# Default installation method (copy all non-toml files)
install_module_default() {
    local module_id="$1"
    local full_target="$2"

    # Copy all files except configz.toml
    find "$CONFIG_SOURCE_DIR/$module_id" -type f ! -name "configz.toml" -exec cp -r {} "$full_target/" \; 2>/dev/null

    # If there are subdirectories, copy them too
    find "$CONFIG_SOURCE_DIR/$module_id" -mindepth 1 -type d -exec cp -r {} "$full_target/" \; 2>/dev/null
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

# Preview what will be installed
preview_installation() {
    local selected_modules
    mapfile -t selected_modules < <(get_selected_modules)

    if [[ ${#selected_modules[@]} -eq 0 ]]; then
        clear
        echo -e "${BOLD}${YELLOW}⚠️  AUCUNE SÉLECTION${NC}"
        echo "════════════════════════════"
        echo
        echo "Aucun module n'est sélectionné pour l'installation."
        echo
        echo -e "Appuyez sur ${BOLD}Entrée${NC} pour retourner au menu..."
        read -r
        return
    fi

    clear
    echo -e "${BOLD}${BLUE}👀 PREVIEW DE L'INSTALLATION${NC}"
    echo "════════════════════════════════════"
    echo
    echo -e "${BOLD}Les modules suivants seront installés :${NC}"
    echo

    for module_id in "${selected_modules[@]}"; do
        local module_name="${MODULE_INFO[${module_id}_name]}"
        local module_desc="${MODULE_INFO[${module_id}_desc]}"
        local target_path="${MODULE_INFO[${module_id}_target]}"
        local full_target="$TARGET_BASE_DIR/$target_path"

        echo -e "  ${GREEN}▶${NC} ${BOLD}$module_name${NC}"
        echo -e "     ${DIM}$module_desc${NC}"
        echo -e "     ${BLUE}→${NC} Destination: ${BOLD}~/.config/$target_path${NC}"

        # Check if target exists
        if [[ -e "$full_target" ]]; then
            if [[ $NO_BACKUP -eq 0 ]]; then
                echo -e "     ${YELLOW}⚠${NC} Fichiers existants seront sauvegardés"
            else
                echo -e "     ${RED}⚠${NC} Fichiers existants seront écrasés (--no-backup)"
            fi
        else
            echo -e "     ${GREEN}✓${NC} Nouvelle installation"
        fi
        echo
    done

    echo -e "${BOLD}Actions prévues :${NC}"
    echo "• Création des dossiers nécessaires"
    if [[ $NO_BACKUP -eq 0 ]]; then
        echo "• Sauvegarde automatique des configurations existantes"
    fi
    echo "• Copie des nouvelles configurations"
    echo "• Affichage des notes post-installation"
    echo

    echo -e "Appuyez sur ${BOLD}Entrée${NC} pour retourner au menu..."
    read -r
}

# Handle keyboard input for checkbox interface
handle_checkbox_input() {
    local key="$1"
    local total_items=${#AVAILABLE_MODULES[@]}

    case "$key" in
        # Navigation
        "k"|$'\033[A')  # Up arrow or k
            if [[ $CURRENT_ITEM -gt 0 ]]; then
                ((CURRENT_ITEM--))
            else
                CURRENT_ITEM=$((total_items - 1))  # Wrap to bottom
            fi
            ;;
        "j"|$'\033[B')  # Down arrow or j
            if [[ $CURRENT_ITEM -lt $((total_items - 1)) ]]; then
                ((CURRENT_ITEM++))
            else
                CURRENT_ITEM=0  # Wrap to top
            fi
            ;;
        " ")  # Spacebar - toggle selection
            local module_id="${AVAILABLE_MODULES[$CURRENT_ITEM]}"
            if [[ ${MODULE_SELECTION["$module_id"]} -eq 1 ]]; then
                MODULE_SELECTION["$module_id"]=0
            else
                MODULE_SELECTION["$module_id"]=1
            fi
            ;;
        "a"|"A")  # Select all
            select_all
            ;;
        "n"|"N")  # Select none
            select_none
            ;;
        $'\n'|$'\r')  # Enter - continue to installation
            # Check if at least one module is selected
            local selected_count=0
            for module in "${AVAILABLE_MODULES[@]}"; do
                if [[ ${MODULE_SELECTION["$module"]} -eq 1 ]]; then
                    ((selected_count++))
                fi
            done

            if [[ $selected_count -eq 0 ]]; then
                # Show error message briefly
                echo -e "\n${YELLOW}⚠️  Sélectionnez au moins un module avant de continuer !${NC}"
                sleep 2
                return 2  # Stay in selection mode
            else
                return 0  # Proceed to installation
            fi
            ;;
        "q"|"Q"|$'\033')  # q, Q, or ESC - quit
            return 1
            ;;
        *)
            # Invalid key, do nothing
            ;;
    esac
    return 2  # Continue selection
}

# Read single key without pressing Enter
read_single_key() {
    local key
    # Save terminal settings
    local old_settings=$(stty -g)
    # Set terminal to raw mode
    stty raw -echo min 0 time 10
    # Read single character
    key=$(dd bs=1 count=1 2>/dev/null)
    # Handle escape sequences (arrow keys)
    if [[ "$key" == $'\033' ]]; then
        key+=$(dd bs=2 count=1 2>/dev/null)
    fi
    # Restore terminal settings
    stty "$old_settings"
    echo "$key"
}

# Phase 1: Selection interface with checkbox navigation
run_selection_phase() {
    CURRENT_ITEM=0  # Reset to first item

    while true; do
        show_checkbox_interface

        local key
        key=$(read_single_key)

        local result
        handle_checkbox_input "$key"
        result=$?

        case $result in
            0)  # Continue to installation
                return 0  # Exit selection phase
                ;;
            1)  # Quit
                clear
                echo -e "${BOLD}${CYAN}👋 Au revoir !${NC}"
                echo -e "${DIM}Merci d'avoir utilisé Configz Installer${NC}"
                exit 0
                ;;
            2)  # Continue in selection mode
                ;;
        esac
    done
}

# Phase 2: Installation interface
run_installation_phase() {
    local selected_modules
    mapfile -t selected_modules < <(get_selected_modules)

    while true; do
        clear
        echo -e "${BOLD}${CYAN}🔧 PHASE 2: INSTALLATION${NC}"
        echo "═══════════════════════════════"
        echo
        echo -e "${BOLD}Modules sélectionnés: ${GREEN}${#selected_modules[@]}${NC}"
        echo

        for module_id in "${selected_modules[@]}"; do
            local module_name="${MODULE_INFO[${module_id}_name]}"
            local module_desc="${MODULE_INFO[${module_id}_desc]}"
            local target_path="${MODULE_INFO[${module_id}_target]}"

            echo -e "  ${GREEN}▶${NC} ${BOLD}$module_name${NC}"
            echo -e "     ${DIM}$module_desc${NC}"
            echo -e "     ${BLUE}→${NC} ~/.config/$target_path"
            echo
        done

        echo -e "${BOLD}🎯 Actions disponibles :${NC}"
        echo -e "  ${GREEN}i${NC} - Installer maintenant"
        echo -e "  ${YELLOW}p${NC} - Preview simple"
        echo -e "  ${YELLOW}d${NC} - Détails avancés"
        echo -e "  ${BLUE}b${NC} - Retour à la sélection"
        echo -e "  ${RED}q${NC} - Quitter"
        echo
        echo -n -e "${BOLD}Votre choix :${NC} "

        read -r choice
        case "$choice" in
            i|I)
                run_installation "${selected_modules[@]}"
                break
                ;;
            p|P)
                preview_installation
                ;;
            d|D)
                show_installation_details "${selected_modules[@]}"
                ;;
            b|B)
                return 1  # Return to selection phase
                ;;
            q|Q)
                clear
                echo -e "${BOLD}${CYAN}👋 Au revoir !${NC}"
                exit 0
                ;;
            *)
                echo -e "\n${RED}Option invalide: $choice${NC}"
                sleep 1
                ;;
        esac
    done
}

# Run the actual installation process
run_installation() {
    local selected_modules=("$@")

    clear
    echo -e "${BOLD}${CYAN}🚀 INSTALLATION EN COURS${NC}"
    echo "═════════════════════════════"
    echo
    echo -e "Installation de ${BOLD}${#selected_modules[@]}${NC} module(s)..."
    echo

    # Ensure target directory exists
    ensure_directory "$TARGET_BASE_DIR"

    # Install each selected module with progress
    local success_count=0
    local failed_modules=()
    local current=1
    local total=${#selected_modules[@]}

    for module_id in "${selected_modules[@]}"; do
        local module_name="${MODULE_INFO[${module_id}_name]}"

        echo -e "${BOLD}[$current/$total]${NC} $module_name"
        echo -n "  → Installation en cours... "

        if install_module "$module_id"; then
            echo -e "${GREEN}✓ Réussi${NC}"
            ((success_count++))
        else
            echo -e "${RED}✗ Échec${NC}"
            failed_modules+=("$module_id")
        fi

        ((current++))
        echo
    done

    # Show final summary
    echo
    echo -e "${BOLD}${GREEN}✨ INSTALLATION TERMINÉE${NC}"
    echo "═══════════════════════════"
    echo -e "Réussis: ${GREEN}$success_count${NC}/$total"

    if [[ ${#failed_modules[@]} -gt 0 ]]; then
        echo -e "Échecs: ${RED}${#failed_modules[@]}${NC} (${failed_modules[*]})"
    fi
    echo

    # Show post-installation notes
    if [[ $success_count -gt 0 ]]; then
        show_post_install_notes "${selected_modules[@]}"
    fi

    echo -e "Appuyez sur ${BOLD}Entrée${NC} pour quitter..."
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
        local tool_name="${MODULE_INFO[${tool_id}_name]}"
        local source_path="$CONFIG_SOURCE_DIR/$tool_id"
        local target_path="${MODULE_INFO[${tool_id}_target]}"
        local full_source="$source_path"
        local full_target="$TARGET_BASE_DIR/$target_path"

        echo -e "${BOLD}$tool_name${NC}"
        echo "────────────────────────────────"
        echo -e "Source      : ${DIM}$full_source${NC}"
        echo -e "Destination : ${DIM}$full_target${NC}"

        # Show source files (macOS compatible)
        if [[ -d "$full_source" ]]; then
            echo -e "Fichiers    : ${DIM}"
            find "$full_source" -type f ! -name "configz.toml" | head -5 | while read -r file; do
                local rel_path=${file#$full_source/}
                echo "              $rel_path"
            done
            local file_count=$(find "$full_source" -type f ! -name "configz.toml" | wc -l | tr -d ' ')
            if [[ $file_count -gt 5 ]]; then
                echo -e "              ... et $((file_count - 5)) autres fichiers"
            fi
            echo -e "${NC}"
        fi

        # Check target status (macOS compatible)
        if [[ -e "$full_target" ]]; then
            local mod_date
            if [[ -f "$full_target" ]]; then
                mod_date=$(stat -f "%Sm" -t "%Y-%m-%d %H:%M" "$full_target" 2>/dev/null || echo "inconnu")
            else
                mod_date=$(stat -f "%Sm" -t "%Y-%m-%d %H:%M" "$full_target" 2>/dev/null || echo "inconnu")
            fi
            echo -e "Status      : ${YELLOW}Existe déjà (modifié le $mod_date)${NC}"
            if [[ $NO_BACKUP -eq 0 ]]; then
                echo -e "Action      : ${YELLOW}Backup + Remplacement${NC}"
            else
                echo -e "Action      : ${RED}Écrasement direct (--no-backup)${NC}"
            fi
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

    # Main loop: Selection -> Installation
    while true; do
        # Phase 1: Selection
        run_selection_phase

        # Phase 2: Installation
        if ! run_installation_phase; then
            # User chose to go back to selection
            continue
        else
            # Installation completed, exit
            break
        fi
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
