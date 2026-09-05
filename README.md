# Dotfiles

Personal configuration files for editor and shell environments.

## Contents

- **vim/.vimrc** - Vim editor configuration with plugins and keybindings
- **ideavim/.ideavimrc** - IdeaVim plugin configuration for JetBrains IDEs
- **starship/.config/starship.toml** - Starship shell prompt configuration
- **omz/.omzrc** - Oh My Zsh plugin list and shell setup
- **fzf/.fzfrc** - FZF key bindings, preview options, and shell integration
- **rule-gof/.copilot/instructions/gof.instructions.md** - GitHub Copilot instruction for OOP design patterns
- **rule-gof/.claude/rules/gof.md** - Claude Code rule for OOP design patterns
- **rule-java/.copilot/instructions/java.instructions.md** - GitHub Copilot instruction for Java style conventions
- **rule-java/.claude/rules/java.md** - Claude Code rule for Java style conventions
- **rule-maven/.copilot/instructions/maven.instructions.md** - GitHub Copilot instruction for Maven build conventions
- **rule-maven/.claude/rules/maven.md** - Claude Code rule for Maven build conventions
- **rule-no-terminal-history/.copilot/instructions/no-terminal-history.instructions.md** - GitHub Copilot instruction to prefix terminal commands with a space
- **rule-no-terminal-history/.claude/rules/no-terminal-history.md** - Claude Code rule to suppress zsh history for terminal commands
- **skill-explain-diff/.claude/skills/explain-diff/SKILL.md** - Claude Code `/explain-diff` skill for analyzing changes between branches
- **skill-explain-diff/.copilot/skills/explain-diff/SKILL.md** - GitHub Copilot equivalent for branch diff analysis
- **skill-explain-pull-request/.claude/skills/explain-pull-request/SKILL.md** - Claude Code `/explain-pull-request` skill for analyzing a PR/MR by number
- **skill-explain-pull-request/.copilot/skills/explain-pull-request/SKILL.md** - GitHub Copilot equivalent for PR analysis
- **skill-create-junit-test/.claude/skills/create-junit-test/SKILL.md** - Claude Code `/create-junit-test` skill for JUnit 5 test generation
- **skill-create-junit-test/.copilot/skills/create-junit-test/SKILL.md** - GitHub Copilot equivalent for JUnit test generation

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
stow -t ~ vim ideavim starship fzf omz
stow --no-folding -t ~ rule-gof rule-java rule-maven rule-no-terminal-history
stow -t ~ skill-explain-diff skill-explain-pull-request skill-create-junit-test
```

This creates symbolic links for:
- `vim/.vimrc` → `~/.vimrc`
- `ideavim/.ideavimrc` → `~/.ideavimrc`
- `starship/.config/starship.toml` → `~/.config/starship.toml`
- `omz/.omzrc` → `~/.omzrc`
- `fzf/.fzfrc` → `~/.fzfrc`
- `rule-gof/.copilot/instructions/gof.instructions.md` → `~/.copilot/instructions/gof.instructions.md`
- `rule-gof/.claude/rules/gof.md` → `~/.claude/rules/gof.md`
- `rule-java/.copilot/instructions/java.instructions.md` → `~/.copilot/instructions/java.instructions.md`
- `rule-java/.claude/rules/java.md` → `~/.claude/rules/java.md`
- `rule-maven/.copilot/instructions/maven.instructions.md` → `~/.copilot/instructions/maven.instructions.md`
- `rule-maven/.claude/rules/maven.md` → `~/.claude/rules/maven.md`
- `rule-no-terminal-history/.copilot/instructions/no-terminal-history.instructions.md` → `~/.copilot/instructions/no-terminal-history.instructions.md`
- `rule-no-terminal-history/.claude/rules/no-terminal-history.md` → `~/.claude/rules/no-terminal-history.md`
- `skill-explain-diff/.claude/skills/explain-diff/SKILL.md` → `~/.claude/skills/explain-diff/SKILL.md`
- `skill-explain-diff/.copilot/skills/explain-diff/SKILL.md` → `~/.copilot/skills/explain-diff/SKILL.md`
- `skill-explain-pull-request/.claude/skills/explain-pull-request/SKILL.md` → `~/.claude/skills/explain-pull-request/SKILL.md`
- `skill-explain-pull-request/.copilot/skills/explain-pull-request/SKILL.md` → `~/.copilot/skills/explain-pull-request/SKILL.md`
- `skill-create-junit-test/.claude/skills/create-junit-test/SKILL.md` → `~/.claude/skills/create-junit-test/SKILL.md`
- `skill-create-junit-test/.copilot/skills/create-junit-test/SKILL.md` → `~/.copilot/skills/create-junit-test/SKILL.md`

### Apply Individual Packages

To apply only specific configurations:

```bash
stow -t ~ vim                          # Vim configuration only
stow -t ~ ideavim                      # IdeaVim configuration only
stow -t ~ starship                     # Starship configuration only
stow -t ~ omz                          # Oh My Zsh configuration only
stow -t ~ fzf                          # FZF configuration only
stow --no-folding -t ~ rule-gof        # OOP design patterns rules (Copilot & Claude Code)
stow --no-folding -t ~ rule-java       # Java style conventions rules (Copilot & Claude Code)
stow --no-folding -t ~ rule-maven      # Maven build conventions rules (Copilot & Claude Code)
stow --no-folding -t ~ rule-no-terminal-history  # Terminal history suppression rule
stow -t ~ skill-explain-diff           # Branch diff analysis skill (Copilot & Claude Code)
stow -t ~ skill-explain-pull-request   # PR analysis skill (Copilot & Claude Code)
stow -t ~ skill-create-junit-test      # JUnit test generation skill (Copilot & Claude Code)
```

### Remove Dotfiles

To remove all symlinks:

```bash
stow -t ~ -D vim ideavim starship fzf omz
stow --no-folding -t ~ -D rule-gof rule-java rule-maven rule-no-terminal-history
stow -t ~ -D skill-explain-diff skill-explain-pull-request skill-create-junit-test
```

Or remove individual packages:

```bash
stow -t ~ -D vim          # Remove Vim configuration
```

## Configuration Notes

- **Vim leader key:** Space
- **`jj` in insert mode:** exits to normal mode (maps to `<Esc>`); works with `set timeout timeoutlen=300`
- **IdeaVim:** Sources `.vimrc`, so shares Vim settings with IDE-specific action mappings on top
- **Starship:** Uses Gruvbox Dark color palette
- **FZF:** Add `[ -f ~/.fzfrc ] && source ~/.fzfrc` to `.zshrc` to activate; the guard makes it safe on machines without fzf
- **OMZ:** Add `[ -f ~/.omzrc ] && source ~/.omzrc` to `.zshrc` to activate
