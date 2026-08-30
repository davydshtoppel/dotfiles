# Dotfiles

Personal configuration files for editor and shell environments.

## Contents

- **vim/.vimrc** - Vim editor configuration with plugins and keybindings
- **ideavim/.ideavimrc** - IdeaVim plugin configuration for JetBrains IDEs
- **starship/.config/starship.toml** - Starship shell prompt configuration
- **rule-gof/.copilot/instructions/gof.instructions.md** - GitHub Copilot instruction for OOP design patterns
- **rule-gof/.claude/rules/gof.md** - Claude Code rule for OOP design patterns
- **rule-java/.copilot/instructions/java.instructions.md** - GitHub Copilot instruction for Java style conventions
- **rule-java/.claude/rules/java.md** - Claude Code rule for Java style conventions
- **rule-maven/.copilot/instructions/maven.instructions.md** - GitHub Copilot instruction for Maven build conventions
- **rule-maven/.claude/rules/maven.md** - Claude Code rule for Maven build conventions
- **skill-review-pr/.claude/skills/review-pr/SKILL.md** - Claude Code `/review-pr` skill for pure-git PR review
- **skill-review-pr/.copilot/skills/review-pr/SKILL.md** - GitHub Copilot equivalent for PR review
- **skill-create-junit-test/.claude/skills/create-junit-test/SKILL.md** - Claude Code `/create-junit-test` skill for JUnit 5 test generation
- **skill-create-junit-test/.copilot/skills/create-junit-test/SKILL.md** - GitHub Copilot equivalent for JUnit test generation
- **fzf/.fzfrc** - FZF key bindings, preview options, and shell integration

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
stow -t ~ vim ideavim starship fzf
stow --no-folding -t ~ rule-gof rule-java rule-maven
stow -t ~ skill-review-pr skill-create-junit-test
```

This creates symbolic links for:
- `vim/.vimrc` → `~/.vimrc`
- `ideavim/.ideavimrc` → `~/.ideavimrc`
- `starship/.config/starship.toml` → `~/.config/starship.toml`
- `rule-gof/.copilot/instructions/gof.instructions.md` → `~/.copilot/instructions/gof.instructions.md`
- `rule-gof/.claude/rules/gof.md` → `~/.claude/rules/gof.md`
- `rule-java/.copilot/instructions/java.instructions.md` → `~/.copilot/instructions/java.instructions.md`
- `rule-java/.claude/rules/java.md` → `~/.claude/rules/java.md`
- `rule-maven/.copilot/instructions/maven.instructions.md` → `~/.copilot/instructions/maven.instructions.md`
- `rule-maven/.claude/rules/maven.md` → `~/.claude/rules/maven.md`
- `skill-review-pr/.copilot/skills/review-pr/SKILL.md` → `~/.copilot/skills/review-pr/SKILL.md`
- `skill-review-pr/.claude/skills/review-pr/SKILL.md` → `~/.claude/skills/review-pr/SKILL.md`
- `skill-create-junit-test/.copilot/skills/create-junit-test/SKILL.md` → `~/.copilot/skills/create-junit-test/SKILL.md`
- `skill-create-junit-test/.claude/skills/create-junit-test/SKILL.md` → `~/.claude/skills/create-junit-test/SKILL.md`
- `fzf/.fzfrc` → `~/.fzfrc`

### Apply Individual Packages

To apply only specific configurations:

```bash
stow -t ~ vim              # Vim configuration only
stow -t ~ ideavim         # IdeaVim configuration only
stow -t ~ starship        # Starship configuration only
stow --no-folding -t ~ rule-gof        # OOP design patterns rules (Copilot & Claude Code)
stow --no-folding -t ~ rule-java       # Java style conventions rules (Copilot & Claude Code)
stow --no-folding -t ~ rule-maven      # Maven build conventions rules (Copilot & Claude Code)
stow -t ~ skill-review-pr              # PR review skill (Copilot & Claude Code)
stow -t ~ skill-create-junit-test      # JUnit test generation skill (Copilot & Claude Code)
stow -t ~ fzf                          # FZF configuration
```

### Remove Dotfiles

To remove all symlinks:

```bash
stow -t ~ -D vim ideavim starship fzf rule-gof rule-java rule-maven skill-review-pr skill-create-junit-test
```

Or remove individual packages:

```bash
stow -t ~ -D vim          # Remove Vim configuration
```

## Configuration Notes

- **Vim leader key:** Space
- **IdeaVim:** Sources `.vimrc`, so shares Vim settings with IDE-specific action mappings
- **Starship:** Uses Gruvbox Dark color palette
- **FZF:** Add `[ -f ~/.fzfrc ] && source ~/.fzfrc` to `.zshrc` to activate; the guard makes it safe on machines without fzf
