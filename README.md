# Configz - Gestionnaire de Configurations

Ce répertoire contient mes configurations personnelles pour différents outils avec un installateur interactif simple et efficace.

## 🚀 Installation Rapide

```bash
# Lancer l'installateur interactif
./install.sh

# Ou encore plus simple
./setup
```

## Structure

```
configz/
├── config/                  # 📦 Configurations
│   ├── fish/
│   │   └── config.fish      # Configuration Fish shell
│   ├── ghostty/
│   │   ├── config           # Configuration principale Ghostty
│   │   └── theme/
│   │       └── main         # Thème Ghostty
│   └── starship/
│       └── starship.toml    # Configuration Starship prompt
├── lib/                     # 📚 Système extensible
│   ├── tools.conf          # Configuration des outils
│   ├── installer.sh        # Module installateur dynamique
│   └── utils.sh            # Utilitaires partagés
├── install.sh              # 🎯 INSTALLATEUR INTERACTIF
├── setup                   # ⚡ Raccourci ultra-rapide
├── .gitignore             # Fichiers à ignorer
└── README.md              # Ce fichier
```

## Utilisation

### 🎯 Utilisation Unique et Simple

Lancez l'installateur interactif qui vous permet de choisir exactement ce que vous voulez installer :

```bash
./install.sh
```

L'installateur vous présente un menu interactif avec :

- 📦 **Sélection par cases à cocher** - Choisissez vos outils
- ⚠️ **Confirmation détaillée** - Voyez exactement ce qui sera installé
- 🔒 **Backups automatiques** - Vos configurations existantes sont sauvegardées
- 📋 **Installation guidée** - Messages clairs à chaque étape

### 📦 Composants

- **`install.sh`** : 🎯 **INSTALLATEUR PRINCIPAL** - Interface interactive avec cases à cocher
- **`setup`** : ⚡ Raccourci rapide vers l'installateur
- **`lib/tools.conf`** : 🔧 Configuration extensible des outils disponibles
- **`lib/installer.sh`** : 📚 Module d'installation dynamique
- **`lib/utils.sh`** : 🛠️ Utilitaires partagés et fonctions communes

### Ce que font les scripts

Les scripts copient automatiquement :

- `config/fish/config.fish` → `~/.config/fish/config.fish`
- `config/ghostty/config` → `~/.config/ghostty/config`
- `config/ghostty/theme/main` → `~/.config/ghostty/theme/main`
- `config/starship/starship.toml` → `~/.config/starship/starship.toml`

### ✨ Fonctionnalités

- ✅ **Menu interactif** avec cases à cocher visuelles (☑/☐)
- ✅ **Sélection granulaire** - Choisissez exactement ce que vous voulez
- ✅ **Confirmation détaillée** - Voyez ce qui sera installé avant de procéder
- ✅ **Backups automatiques** avec timestamp des configurations existantes
- ✅ **Interface colorée** et intuitive
- ✅ **Messages informatifs** à chaque étape
- ✅ **Résumé détaillé** post-installation avec instructions
- ✅ **Architecture extensible** - Facile d'ajouter de nouveaux outils

### Déploiement manuel

Si tu préfères copier manuellement :

```bash
# Fish
mkdir -p ~/.config/fish
cp fish/config.fish ~/.config/fish/config.fish

# Ghostty
mkdir -p ~/.config/ghostty/theme
cp ghostty/config ~/.config/ghostty/config
cp ghostty/theme/main ~/.config/ghostty/theme/main

# Starship
mkdir -p ~/.config/starship
cp starship/starship.toml ~/.config/starship/starship.toml
```

## Après le déploiement

1. **Fish** : Redémarre ton terminal ou exécute `source ~/.config/fish/config.fish`
2. **Ghostty** : Redémarre Ghostty si il était ouvert
3. **Starship** : Assure-toi que Starship est installé et configuré dans ton shell

## Sauvegarde

L'installateur crée automatiquement des backups de tes configurations existantes avec un timestamp, par exemple :
- `~/.config/fish/config.fish.backup.20241220_143022`

## 🎯 Utilisation Simple

Pour installer vos configurations, lancez simplement :

```bash
./install.sh
# ou
./setup
```

L'installateur vous guide through un processus simple et interactif.

## 📸 Aperçu de l'Interface

### Interface de l'Installateur
```
╔══════════════════════════════════════════════════════════════════════════════╗
║                                                                              ║
║                          🎛️  CONFIGZ INSTALLER                             ║
║                                                                              ║
║              Sélectionnez les configurations à installer                    ║
║                                                                              ║
╚══════════════════════════════════════════════════════════════════════════════╝

📦 Configurations disponibles :

  ☑ 1. 🐟 Fish Shell
     Shell interactif moderne avec autocomplétion intelligente
     └─ Target: ~/.config/fish
     Status: Sélectionné

  ☐ 2. 👻 Ghostty Terminal
     Terminal haute performance avec rendu GPU
     └─ Target: ~/.config/ghostty
     Status: Non sélectionné

  ☑ 3. ⭐ Starship Prompt
     Prompt cross-shell rapide et personnalisable
     └─ Target: ~/.config/starship
     Status: Sélectionné

🎮 Actions disponibles :
  1-3 - Basculer la sélection d'un outil
  a - Tout sélectionner
  n - Tout désélectionner
  i - Installer les configurations sélectionnées
  s - Afficher le statut
  q - Quitter
```

## 🔧 Prérequis

- Système Unix/Linux
- Bash 4.0+
- Commandes de base : `cp`, `mkdir`, `grep`, `find`

## ⚡ Démarrage Ultra-Rapide

```bash
# Dans le dossier configz
./install.sh

# Ou encore plus simple
./setup

# C'est tout ! L'interface interactive vous guide.
```

## 🔧 Extensibilité

### Ajouter de nouveaux outils

Le système est conçu pour être facilement extensible. Pour ajouter un nouvel outil :

1. **Ajouter la configuration** dans `config/nom_outil/`
2. **Déclarer l'outil** dans `lib/tools.conf` :
   ```
   nom_outil|🔧 Nom Outil|Description de l'outil|config/nom_outil|.config/nom_outil|install_nom_outil
   ```
3. **Créer la fonction d'installation** (optionnel) dans `lib/installer.sh`

### Format du fichier tools.conf

Chaque ligne suit ce format :
```
TOOL_ID|DISPLAY_NAME|DESCRIPTION|SOURCE_PATH|TARGET_PATH|INSTALL_FUNCTION
```

**Exemple pour ajouter Neovim :**
```
nvim|⚡ Neovim|Éditeur de texte moderne et extensible|config/nvim|.config/nvim|install_nvim
```

### Outils prêts à ajouter

Des exemples sont déjà préparés dans `lib/tools.conf` :
- **Neovim** - Éditeur de texte moderne
- **Tmux** - Multiplexeur de terminal  
- **Git** - Configuration Git globale
- **Zsh** - Shell Z avec Oh My Zsh
- **Alacritty** - Terminal rapide avec GPU
- **VS Code** - Paramètres et extensions

## 📋 Avantages

- ✅ **Une seule commande** - `./install.sh` et c'est parti
- 🔒 **Zéro perte** - Backups automatiques de vos configurations existantes
- 🎯 **Choix précis** - Installez seulement ce que vous voulez
- ⚠️ **Confirmation claire** - Voyez exactement ce qui sera installé
- 🖥️ **Compatible** avec tous les systèmes Unix/Linux
- 🔧 **Extensible** - Facile d'ajouter de nouveaux outils
- 🚀 **Simple** - Interface intuitive, pas de complexité inutile