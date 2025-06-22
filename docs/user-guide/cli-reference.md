# Configz CLI - Guide d'utilisation

![Configz Logo](https://img.shields.io/badge/Configz-CLI-blue?style=for-the-badge)

Un CLI moderne et modulaire pour gérer tes configurations dotfiles avec style ! 🚀

## 📍 Structure par défaut

Configz utilise par défaut le répertoire `~/.config/configz/modules/` pour stocker vos modules de configuration. Ce répertoire est personnel et n'est pas versionné avec le CLI.

```
~/.config/configz/
├── modules/                   # Vos modules de configuration
│   ├── fish/                  # Configuration Fish shell
│   ├── nvim/                  # Configuration Neovim
│   └── starship/              # Configuration Starship
├── backups/                   # Sauvegardes automatiques
└── config.toml               # Configuration globale
```

## 🎯 Installation

### Installation Automatique

```bash
# Installer le CLI globalement
./install-cli.sh

# Ou installation système (nécessite sudo)
sudo ./install-cli.sh --system
```

### Première utilisation

```bash
# Créer le répertoire des modules (première fois)
mkdir -p ~/.config/configz/modules

# Vérifier l'installation
configz --version
configz list
```

## 🎮 Commandes Principales

### 📋 Lister les modules

```bash
# Lister tous les modules
configz list

# Modules installés seulement
configz list --installed

# Format détaillé
configz list --long

# Format JSON pour scripts
configz list --json
```

**Sortie exemple :**
```
Configz Modules
Source: /Users/user/.config/configz/modules
Target: /Users/user/.config

ST  ICON NAME                 DESCRIPTION
--- ---- -------------------- --------------------
✓   🐟   Fish Shell          Shell interactif moderne
○   👻   Ghostty Terminal    Terminal haute performance
✓   ⭐   Starship Prompt     Prompt cross-shell rapide

Total: 3 modules
```

### 🔧 Installer des modules

```bash
# Installation interactive (recommandé)
configz install

# Installer des modules spécifiques
configz install fish starship nvim

# Installer tous les modules
configz install --all

# Installation sans backup
configz install --no-backup fish

# Aperçu sans installation
configz install --dry-run fish
```

### 📊 Statut des installations

```bash
# Statut général
configz status

# Statut détaillé
configz status --detailed

# Modules spécifiques
configz status fish nvim

# Format JSON
configz status --json
```

### ℹ️ Informations détaillées

```bash
# Infos complètes sur un module
configz info fish

# Avec liste des fichiers
configz info --files nvim

# Avec dépendances
configz info --deps starship

# Toutes les infos
configz info --all fish
```

**Sortie exemple :**
```
🐟 Fish Shell
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Module ID:     fish
Description:   Shell interactif moderne avec autocomplétion intelligente
Version:       1.0.0
Author:        Configz

Paths:
  Source:  ./config/fish
  Target:  ~/.config/fish

Status:
  ✓ Installed
  Files:        20
  Size:         80K
  Modified:     2024-12-20 13:52:34
  Backups:      1 found
```

### 🗑️ Supprimer des modules

```bash
# Supprimer un module
configz remove fish

# Suppression sans confirmation
configz remove --force fish

# Aperçu avant suppression
configz remove --dry-run fish
```

### 💾 Gestion des backups

```bash
# Backup d'un module
configz backup fish

# Backup de tous les modules installés
configz backup --all

# Restaurer depuis un backup
configz restore fish
```

## 🎨 Options Globales

| Option | Description |
|--------|-------------|
| `-h, --help` | Afficher l'aide |
| `-V, --version` | Version du programme |
| `-v, --verbose` | Mode verbeux |
| `-q, --quiet` | Mode silencieux |
| `-n, --dry-run` | Simulation sans exécution |
| `--no-backup` | Pas de backup automatique |
| `-f, --force` | Forcer sans confirmation |
| `--config-dir DIR` | Répertoire config personnalisé |
| `--modules-dir DIR` | Répertoire modules personnalisé |

## 🧩 Créer tes propres modules

### Structure basique

```bash
# Créer un nouveau module
mkdir config/mon-outil
```

### Fichiers de configuration

Ajoute tes fichiers de config dans le dossier :

```
config/mon-outil/
├── config.yml          # Fichier principal
├── themes/             # Dossier de thèmes
│   └── dark.yml
└── configz.toml        # Métadonnées (optionnel)
```

### Configuration avancée (configz.toml)

```toml
[module]
name = "Mon Super Outil"
description = "Configuration pour mon outil génial"
icon = "🔧"
version = "2.1.0"
author = "Ton Nom"

[installation]
type = "copy"  # ou "symlink"

[paths]
target = "mon-outil"  # Dossier dans ~/.config/

[dependencies]
system = ["mon-outil", "git"]
modules = []

[post_install]
notes = [
    "Redémarre l'application",
    "Lance: mon-outil --reload"
]
```

## 🔍 Recherche et découverte

```bash
# Rechercher des modules
configz search "fish"

# Vérifier la santé du système
configz doctor

# Mettre à jour des modules
configz update fish starship
```

## 🎯 Exemples d'usage

### Workflow typique

```bash
# 1. Voir les modules disponibles
configz list

# 2. Installation interactive
configz install

# 3. Vérifier le statut
configz status

# 4. Infos sur un module
configz info fish

# 5. Backup avant changements
configz backup --all
```

### Scripts automatisés

```bash
# Installation complète pour nouveau système
configz install --all --force

# Backup quotidien
configz backup --all --quiet

# Statut en JSON pour monitoring
configz status --json | jq '.summary.installed'
```

### Gestion par environnement

```bash
# Environnement de développement
configz --modules-dir ~/dev-configs --config-dir ~/dev-dotfiles install fish nvim

# Configuration serveur
configz --modules-dir ~/server-configs install starship

# Utiliser un répertoire de modules personnalisé
configz --modules-dir ~/my-dotfiles list
```

## 🐟 Auto-complétion

L'auto-complétion est installée automatiquement pour :

- **Bash** : `~/.local/share/bash-completion/completions/configz`
- **Zsh** : `~/.local/share/zsh/site-functions/_configz`
- **Fish** : `./completions/configz.fish`

### Activation manuelle Fish

```bash
# Copier le fichier de complétion
cp completions/configz.fish ~/.config/fish/completions/
```

## 🆘 Dépannage

### Commandes de diagnostic

```bash
# Vérification système
configz doctor

# Mode verbeux pour debug
configz --verbose list

# Forcer la réinstallation
configz install --force fish
```

### Problèmes courants

#### Module non trouvé
```bash
# Vérifier la structure
ls -la config/
configz list
```

#### Erreurs de permissions
```bash
# Réinstaller avec les bonnes permissions
./install-cli.sh
```

#### yq manquant
```bash
# Installer yq (requis pour TOML)
brew install yq
```

## 📚 Documentation

- **Page de manuel** : `man configz`
- **Aide contextuelle** : `configz <commande> --help`
- **Code source** : Structure modulaire dans `cli/`

## 🔧 Désinstallation

```bash
# Supprimer le CLI
./install-cli.sh --uninstall

# Nettoyer les configs (optionnel)
rm -rf ~/.config/fish ~/.config/starship  # etc.
```

## 🚀 Avantages du CLI

✅ **Interface moderne** - Navigation intuitive  
✅ **Auto-complétion** - Support multi-shell  
✅ **Formats multiples** - JSON, texte, couleurs  
✅ **Gestion d'erreurs** - Messages clairs  
✅ **Extensible** - Ajoute tes modules facilement  
✅ **Sécurisé** - Backups automatiques  
✅ **Scriptable** - Options pour automation  

## 🎉 Exemple complet

```bash
# Installation du CLI
./install-cli.sh

# Découverte des modules
configz list

# Installation interactive
configz install
# → Sélectionne fish, starship, nvim avec ↑↓ et espace

# Vérification
configz status --detailed

# Infos sur un module
configz info --all fish

# Backup avant changements
configz backup --all

# Bon coding! 🎯
```

---

**Configz CLI v0.2.1-alpha** - Fait avec ❤️ pour les développeurs qui aiment les configs propres !