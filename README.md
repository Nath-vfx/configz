# Configz - Gestionnaire de Configurations Modulaire

Gestionnaire de configurations personnel avec système d'auto-découverte et interface moderne par cases à cocher.

## 🚀 Installation Ultra-Rapide

```bash
# Lancer l'installateur interactif moderne
./install.sh

# Ou utiliser le raccourci
./setup
```

## ✨ Fonctionnalités

- 🎯 **Interface moderne** avec navigation par flèches (↑↓) et sélection par espace
- 📦 **Auto-découverte** - Détecte automatiquement tous les modules dans `config/`
- ⚙️ **Configuration optionnelle** - Fonctionne avec ou sans fichiers `configz.toml`
- 🔒 **Backups automatiques** avec horodatage des configurations existantes
- 🎨 **Interface colorée** et intuitive en 2 phases distinctes
- 🔧 **Extensibilité infinie** - Ajoutez un dossier = nouveau module disponible
- ⚡ **Installation en batch** avec barre de progression

## 📁 Structure

```
configz/
├── config/                  # 📦 Modules de configuration
│   ├── fish/
│   │   ├── config.fish      # Configuration Fish shell
│   │   └── configz.toml     # (optionnel) Métadonnées du module
│   ├── ghostty/
│   │   ├── config           # Configuration Ghostty
│   │   ├── theme/main       # Thème personnalisé
│   │   └── configz.toml     # Configuration du module
│   ├── starship/
│   │   ├── starship.toml    # Configuration Starship
│   │   └── configz.toml     # Métadonnées
│   ├── nvim/
│   │   ├── init.lua         # Configuration Neovim
│   │   └── configz.toml     # Configuration avancée
│   └── your_tool/           # 🆕 Ajoutez votre module ici !
│       ├── config.file      # Vos fichiers de config
│       └── configz.toml     # (optionnel) Personnalisation
├── install.sh              # 🎯 INSTALLATEUR PRINCIPAL
├── setup                   # ⚡ Raccourci rapide
└── README.md              # Documentation
```

## 🎮 Interface Moderne

### Phase 1 : Sélection Interactive
```
╔══════════════════════════════════════════════════════════════════════════════╗
║                     🎛️  PHASE 1: SÉLECTION DES MODULES                     ║
║               Utilisez ↑↓ pour naviguer, ESPACE pour sélectionner          ║
╚══════════════════════════════════════════════════════════════════════════════╝

📦 Configurations disponibles :

▶ [✓] 🐟 Fish Shell
    Shell interactif moderne avec autocomplétion intelligente
    → ~/.config/fish

  [ ] 👻 Ghostty Terminal ●
    Terminal haute performance avec rendu GPU
    → ~/.config/ghostty

  [✓] ⭐ Starship Prompt
    Prompt cross-shell rapide et personnalisable
    → ~/.config/starship

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📊 Sélectionnés: 2/4  Page: 1/1

🎮 Contrôles :
  ↑/k Haut    ↓/j Bas    ESPACE Sélectionner    a Tout    n Rien
  ENTRÉE Continuer    q/ESC Quitter
```

### Phase 2 : Installation
```
🔧 PHASE 2: INSTALLATION
═══════════════════════════════

Modules sélectionnés: 2

  ▶ 🐟 Fish Shell
     Shell interactif moderne avec autocomplétion intelligente
     → ~/.config/fish

  ▶ ⭐ Starship Prompt
     Prompt cross-shell rapide et personnalisable
     → ~/.config/starship

🎯 Actions disponibles :
  i - Installer maintenant
  p - Preview simple
  d - Détails avancés
  b - Retour à la sélection
  q - Quitter
```

## 🔧 Utilisation

### Options en ligne de commande

```bash
./install.sh                # Installation normale avec backup
./install.sh --no-backup   # Installation sans sauvegarde
./install.sh --dry-run     # Mode simulation
./install.sh --help        # Afficher l'aide
```

### Navigation par clavier

- **↑/↓ ou k/j** : Naviguer dans la liste
- **ESPACE** : Sélectionner/désélectionner
- **a** : Tout sélectionner
- **n** : Tout désélectionner
- **ENTRÉE** : Continuer vers l'installation
- **q/ESC** : Quitter

## 📦 Système Modulaire

### Auto-découverte

Le système détecte automatiquement tous les dossiers dans `config/` et les propose comme modules installables. Aucune configuration manuelle requise !

### Configuration avancée avec `configz.toml`

Pour personnaliser un module, créez un fichier `configz.toml` dans son dossier :

```toml
[module]
name = "Mon Super Outil"
description = "Description détaillée de l'outil"
icon = "🚀"
version = "1.0.0"
author = "Votre Nom"

[installation]
type = "copy"  # ou "symlink"

[paths]
target = "mon-outil"  # Dossier dans ~/.config/
sources = ["config.yml", "themes/"]

[dependencies]
system = ["mon-outil"]  # Paquets requis
modules = []  # Autres modules configz requis

[post_install]
notes = [
    "Redémarrez l'application",
    "Exécutez: mon-outil --reload"
]

[backup]
strategy = "auto"  # "auto", "manual", "none"
files = ["config.yml"]
directories = ["themes"]
```

### Configuration par défaut (sans configz.toml)

Si aucun `configz.toml` n'existe, le système utilise des valeurs par défaut intelligentes :

- **Nom** : Nom du dossier capitalisé
- **Description** : "Configuration pour [Nom]"
- **Icône** : 📦
- **Installation** : Copie tous les fichiers (sauf configz.toml)
- **Destination** : `~/.config/[nom-du-dossier]`

## 🆕 Ajouter un Nouveau Module

C'est ultra simple ! Créez juste un dossier dans `config/` :

```bash
# Étape 1 : Créer le dossier
mkdir config/my-awesome-tool

# Étape 2 : Ajouter vos fichiers de config
cp ~/my-config.yml config/my-awesome-tool/

# Étape 3 : (Optionnel) Personnaliser
cat > config/my-awesome-tool/configz.toml << EOF
[module]
name = "My Awesome Tool"
description = "Configuration pour mon outil génial"
icon = "🔧"
EOF

# C'est tout ! Votre module apparaît automatiquement dans l'installateur
./install.sh
```

## 🔒 Sécurité et Backups

- **Backups automatiques** : `config.fish.backup.20241220_143022`
- **Mode sans backup** : `--no-backup` pour éviter les sauvegardes
- **Preview détaillé** : Voyez exactement quels fichiers seront copiés
- **Installation non-destructive** : Toujours possible de revenir en arrière

## 🎯 Exemples d'utilisation

### Installation interactive complète
```bash
./install.sh
# Sélectionnez vos modules avec ↑↓ et ESPACE
# Appuyez sur ENTRÉE pour installer
```

### Installation rapide sans backup
```bash
./install.sh --no-backup
```

### Simulation pour voir ce qui sera installé
```bash
./install.sh --dry-run
```

## 🔧 Prérequis

- **Bash 4.0+** (pour les tableaux associatifs)
- **yq** (installé automatiquement via Homebrew si absent)
- Commandes standard : `cp`, `mkdir`, `find`

## 🌟 Avantages

✅ **Extensibilité infinie** - Ajoutez un dossier = nouveau module  
✅ **Interface moderne** - Navigation intuitive par clavier  
✅ **Auto-découverte** - Zéro configuration manuelle  
✅ **Deux phases distinctes** - Sélection puis installation  
✅ **Backups automatiques** - Zéro risque de perte  
✅ **Configuration optionnelle** - Fonctionne out-of-the-box  
✅ **Preview détaillé** - Transparence totale  
✅ **Compatible** - Tous systèmes Unix/Linux/macOS  

## 📋 Déploiement

Après installation, redémarrez vos applications ou suivez les notes spécifiques à chaque module affichées en fin d'installation.

**C'est tout !** 🎉 Votre système de configuration modulaire est prêt à l'emploi.