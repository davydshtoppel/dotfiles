# Dotfiles

Personal configuration files for editor and shell environments.

## Contents

- **vim/.vimrc** - Vim editor configuration with plugins and keybindings
- **ideavim/.ideavimrc** - IdeaVim plugin configuration for JetBrains IDEs
- **starship/.config/starship.toml** - Starship shell prompt configuration
- **rule-gof/.github/gof.instructions.md** - GitHub Copilot instruction for OOP design patterns
- **rule-gof/.claude/rules/gof.md** - Claude Code rule for OOP design patterns
- **rule-java/.github/java.instructions.md** - GitHub Copilot instruction for Java style conventions
- **rule-java/.claude/rules/java.md** - Claude Code rule for Java style conventions

## Installation

These dotfiles are managed with [stow](https://www.gnu.org/software/stow/), which creates symbolic links from the dotfiles directory to your home directory.

### Prerequisites

Install stow:
```bash
# macOS
brew install stow

# Linux (Ubuntu/Debian)
sudo apt-get install stow
```

### Apply Dotfiles

Since this repository is typically cloned to a location other than the home directory, use stow with the `-t` flag to specify your home directory as the target:

```bash
cd /path/to/dotfiles
stow -t ~ vim ideavim starship
stow --no-folding -t ~ rule-gof rule-java
```

This creates symbolic links for:
- `vim/.vimrc` → `~/.vimrc`
- `ideavim/.ideavimrc` → `~/.ideavimrc`
- `starship/.config/starship.toml` → `~/.config/starship.toml`
- `rule-gof/.github/gof.instructions.md` → `~/.github/gof.instructions.md`
- `rule-gof/.claude/rules/gof.md` → `~/.claude/rules/gof.md`
- `rule-java/.github/java.instructions.md` → `~/.github/java.instructions.md`
- `rule-java/.claude/rules/java.md` → `~/.claude/rules/java.md`

### Apply Individual Packages

To apply only specific configurations:

```bash
stow -t ~ vim              # Vim configuration only
stow -t ~ ideavim         # IdeaVim configuration only
stow -t ~ starship        # Starship configuration only
stow --no-folding -t ~ rule-gof        # OOP design patterns rules (Copilot & Claude Code)
stow --no-folding -t ~ rule-java       # Java style conventions rules (Copilot & Claude Code)
```

### Remove Dotfiles

To remove all symlinks:

```bash
stow -t ~ -D vim ideavim starship rule-gof rule-java
```

Or remove individual packages:

```bash
stow -t ~ -D vim          # Remove Vim configuration
```

## Configuration Notes

- **Vim leader key:** Space
- **IdeaVim:** Sources `.vimrc`, so shares Vim settings with IDE-specific action mappings
- **Starship:** Uses Gruvbox Dark color palette
