# Dotfiles

Personal configuration files for editor and shell environments.

## Contents

- **vim/.vimrc** - Vim editor configuration with plugins and keybindings
- **ideavim/.ideavimrc** - IdeaVim plugin configuration for JetBrains IDEs
- **starship/.config/starship.toml** - Starship shell prompt configuration
- **omz/.omzrc** - Oh My Zsh plugin list and shell setup
- **fzf/.fzfrc** - FZF key bindings, preview options, and shell integration
- **ltree/.local/bin/ltree** - Colorized `tree`-mimicking script used by the FZF Alt-C preview (no Homebrew `tree` dependency)
- **vscode/Library/Application Support/Code/User/settings.json** - VS Code user settings (macOS), including VSCodeVim config mirroring `.vimrc`
- **rule-java/.copilot/instructions/java.instructions.md** - GitHub Copilot instruction for Java design and style
- **rule-java/.claude/rules/java.md** - Claude Code rule for Java design and style
- **skill-explain-diff/.claude/skills/explain-diff/SKILL.md** - Claude Code `/explain-diff` skill for analyzing changes between branches
- **skill-explain-diff/.agents/skills/explain-diff/SKILL.md** - GitHub Copilot equivalent for branch diff analysis
- **skill-explain-pull-request/.claude/skills/explain-pull-request/SKILL.md** - Claude Code `/explain-pull-request` skill for analyzing a PR/MR by number
- **skill-explain-pull-request/.agents/skills/explain-pull-request/SKILL.md** - GitHub Copilot equivalent for PR analysis
- **skill-create-junit-test/.claude/skills/create-junit-test/SKILL.md** - Claude Code `/create-junit-test` skill for JUnit 5 test generation
- **skill-create-junit-test/.agents/skills/create-junit-test/SKILL.md** - GitHub Copilot equivalent for JUnit test generation
- **skill-atelier/.claude/skills/atelier/SKILL.md** + **skill-atelier/.claude/agents/atelier-*.md** - Claude Code `/atelier` atelier (explorer → planner → implementer → reviewer with two approval checkpoints)
- **skill-atelier/.copilot/agents/atelier*.agent.md** - GitHub Copilot equivalent (`atelier` custom agent + subagents) for VS Code and Copilot CLI
- **skill-atelier/.local/bin/atelier** - bash script (3.2 compatible) that does the atelier's deterministic bookkeeping (state, usage ledger, validate, gates, verify runs, diffs, report); `tests/atelier.test.sh` is its smoke test

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
stow -t ~ vim ideavim starship fzf omz ltree
stow --no-folding -t ~ skill-explain-diff skill-explain-pull-request skill-create-junit-test
stow --no-folding -t ~ skill-atelier
stow --no-folding -t ~ vscode   # macOS only
```

This creates symbolic links for:
- `vim/.vimrc` → `~/.vimrc`
- `ideavim/.ideavimrc` → `~/.ideavimrc`
- `starship/.config/starship.toml` → `~/.config/starship.toml`
- `omz/.omzrc` → `~/.omzrc`
- `fzf/.fzfrc` → `~/.fzfrc`
- `ltree/.local/bin/ltree` → `~/.local/bin/ltree`
- `vscode/Library/Application Support/Code/User/settings.json` → `~/Library/Application Support/Code/User/settings.json`
- `rule-java/.copilot/instructions/java.instructions.md` → `~/.copilot/instructions/java.instructions.md`
- `rule-java/.claude/rules/java.md` → `~/.claude/rules/java.md`
- `skill-explain-diff/.claude/skills/explain-diff/SKILL.md` → `~/.claude/skills/explain-diff/SKILL.md`
- `skill-explain-diff/.agents/skills/explain-diff/SKILL.md` → `~/.agents/skills/explain-diff/SKILL.md`
- `skill-explain-pull-request/.claude/skills/explain-pull-request/SKILL.md` → `~/.claude/skills/explain-pull-request/SKILL.md`
- `skill-explain-pull-request/.agents/skills/explain-pull-request/SKILL.md` → `~/.agents/skills/explain-pull-request/SKILL.md`
- `skill-create-junit-test/.claude/skills/create-junit-test/SKILL.md` → `~/.claude/skills/create-junit-test/SKILL.md`
- `skill-create-junit-test/.agents/skills/create-junit-test/SKILL.md` → `~/.agents/skills/create-junit-test/SKILL.md`
- `skill-atelier/.claude/skills/atelier/SKILL.md` → `~/.claude/skills/atelier/SKILL.md`
- `skill-atelier/.claude/agents/atelier-{explorer,planner,implementer,reviewer}.md` → `~/.claude/agents/`
- `skill-atelier/.copilot/agents/atelier{,-explorer,-planner,-implementer,-reviewer}.agent.md` → `~/.copilot/agents/`
- `skill-atelier/.local/bin/atelier` → `~/.local/bin/atelier` (`tests/` is not linked, see `.stow-local-ignore`)

### Apply Individual Packages

To apply only specific configurations:

```bash
stow -t ~ vim                          # Vim configuration only
stow -t ~ ideavim                      # IdeaVim configuration only
stow -t ~ starship                     # Starship configuration only
stow -t ~ omz                          # Oh My Zsh configuration only
stow -t ~ fzf                          # FZF configuration only
stow -t ~ ltree                        # tree-mimicking script for FZF Alt-C preview
stow --no-folding -t ~ vscode          # VS Code settings (macOS)
stow --no-folding -t ~ rule-java       # Java design & style rules (Copilot & Claude Code)
stow --no-folding -t ~ skill-explain-diff           # Branch diff analysis skill (Copilot & Claude Code)
stow --no-folding -t ~ skill-explain-pull-request   # PR analysis skill (Copilot & Claude Code)
stow --no-folding -t ~ skill-create-junit-test      # JUnit test generation skill (Copilot & Claude Code)
stow --no-folding -t ~ skill-atelier       # atelier skill + subagents (Copilot & Claude Code)
```

### Migrating Copilot skills to ~/.agents/skills

Copilot skills (`skill-explain-diff`, `skill-explain-pull-request`, `skill-create-junit-test`) used to be stowed into `~/.copilot/skills/`; they now go to `~/.agents/skills/`, which Copilot and other harnesses read. On a machine stowed with the old layout, `git pull` leaves dangling links, so `stow -D` can no longer find them. Clean up and restow:

```bash
find ~/.copilot/skills -type l -lname '*dotfiles/skill-*' -delete   # dangling links into this repo
find ~/.copilot/skills -mindepth 1 -type d -empty -delete
rmdir ~/.copilot/skills 2>/dev/null
# move aside any real ~/.agents/skills/<name> directory that stow reports as a conflict
stow -R --no-folding -t ~ skill-explain-diff skill-explain-pull-request skill-create-junit-test
```

Use `--no-folding` so `~/.agents/skills/` stays a real directory shared with `npx skills` installs.

### Remove Dotfiles

To remove all symlinks:

```bash
stow -t ~ -D vim ideavim starship fzf omz ltree
stow --no-folding -t ~ -D rule-java
stow --no-folding -t ~ -D skill-explain-diff skill-explain-pull-request skill-create-junit-test
stow --no-folding -t ~ -D skill-atelier
stow --no-folding -t ~ -D vscode
```

Or remove individual packages:

```bash
stow -t ~ -D vim          # Remove Vim configuration
```

## Configuration Notes

- **Vim leader key:** Space
- **`jj` in insert mode:** exits to normal mode (maps to `<Esc>`); works with `set timeout timeoutlen=500`
- **IdeaVim:** Sources `.vimrc`, so shares Vim settings with IDE-specific action mappings on top
- **Starship:** Uses Gruvbox Dark color palette
- **FZF:** Add `[ -f ~/.fzfrc ] && source ~/.fzfrc` to `.zshrc` to activate; the guard makes it safe on machines without fzf
- **OMZ:** Add `[ -f ~/.omzrc ] && source ~/.omzrc` to `.zshrc` to activate
- **ltree:** `ltree/.local/bin/ltree` is a small zsh script mimicking `tree -C` for machines without Homebrew's `tree` (used by `fzf`'s Alt-C preview via `FZF_ALT_C_OPTS`). Ensure `~/.local/bin` is on `PATH` in `.zshrc` (e.g. `export PATH="$HOME/.local/bin:$PATH"`) so it can be found
- **VS Code:** macOS only. Stow with `--no-folding` so `~/Library/Application Support/Code/User/` stays a real directory (it holds machine-local state). If a real `settings.json` already exists there, move it away first (stow will not overwrite it). Avoid enabling Settings Sync for `settings.json` alongside stow
- **skill-atelier:** Entry point is `/atelier <JIRA-KEY | task>` in Claude Code, or the `atelier` agent in VS Code (agent picker) / Copilot CLI (`copilot --agent atelier`, interactive only). Flow: explore (light model) → plan (strong, plus a cheap plan gate) → **checkpoint 1** → baseline verify → implement (mid) → gates (scope, planned tests present, no weakened tests) → verify (+ lint) → review (strong, diff only, once; after a review fix, one focused recheck of the fix diff) → **checkpoint 2** → full suite before push → commit/PR (or leave the changes as is, or abort and discard them). The Claude Code orchestrator itself runs on Sonnet. The orchestrator never does subagent work itself: a preflight stops the run if no subagent tool exists (VS Code needs the `agent` tool and `chat.customAgentInSubagent.enabled`), and a handoff file without a `usage.md` row is rejected. All deterministic bookkeeping (`state.md`/`usage.md` writes, handoff validation, plan gate, gates, verify/lint/full runs with a 570 s time limit, snapshot and review diffs, baseline comparison, usage report) is done by the `atelier` script, so the orchestrator only routes on its exit codes; the preflight stops the run if the script is not on `PATH` (stow the package and add `~/.local/bin` to `PATH`). A usage ledger (`usage.md`: one row per subagent spawn and per verify/lint/full-suite run) is summarized at the end of a run: per-agent totals, retry/deviation/fix counts, command results. Tokens are approximate; on Copilot CLI only model and measured duration are logged (tokens via `/usage`). Runs are stored in `<project>/.atelier/runs/<id>/` (added to `.git/info/exclude`) and can be continued with `resume <id>`. No per-project config: the verify command, commit/branch conventions, and the JIRA/PR tools (project skills, MCP, `gh`/`glab`) are auto-detected each run. Keep `git push` behind an approval prompt (`"ask": ["Bash(git push *)"]` in `~/.claude/settings.json`; avoid `--allow-all` in Copilot CLI). Copilot `model:` lists start with the Copilot CLI ID (the CLI only tries the first entry and falls back to `auto` if it is unavailable), followed by VS Code display names (VS Code tries each in order). Adjust them to your subscription, or override per subagent in `~/.copilot/settings.json` via `subagents.agents.<name>.model`
