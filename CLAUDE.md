# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

This is a personal dotfiles repository containing editor and shell configurations:
- **vim/.vimrc** - Vim editor configuration with plugins and keybindings
- **ideavim/.ideavimrc** - IdeaVim plugin configuration for JetBrains IDEs
- **starship/.config/starship.toml** - Starship shell prompt configuration
- **rule-gof/.copilot/instructions/gof.instructions.md** - GitHub Copilot instruction for OOP design patterns
- **rule-gof/.claude/rules/gof.md** - Claude Code rule for Gang of Four patterns and SOLID principles
- **rule-java/.copilot/instructions/java.instructions.md** - GitHub Copilot instruction for Java style conventions
- **rule-java/.claude/rules/java.md** - Claude Code rule for Java style conventions
- **rule-maven/.copilot/instructions/maven.instructions.md** - GitHub Copilot instruction for Maven build conventions
- **rule-maven/.claude/rules/maven.md** - Claude Code rule for Maven build conventions
- **skill-review-pr/.claude/skills/review-pr/SKILL.md** - Claude Code `/review-pr` skill for pure-git PR review
- **skill-review-pr/.copilot/skills/review-pr/SKILL.md** - GitHub Copilot equivalent for PR review

## Architecture & Key Relationships

### Vim Configuration Structure
The Vim configuration uses vim-plug for plugin management. Plugins are declared in `.vimrc` with `call plug#begin()` and `call plug#end()` blocks. Currently includes:
- `vim-log-highlighting` - Syntax highlighting for log files
- `vim-highlightedyank` - Visual feedback when yanking text
- `vim-commentary` - Comment/uncomment operator
- `nerdtree` - File tree explorer
- `rainbow_csv` - CSV file syntax highlighting

### IdeaVim Relationship
The `.ideavimrc` sources `.vimrc` at the top (line 7: `source ~/.vimrc`), so they share Vim settings. IdeaVim then adds IDE-specific action mappings that map Vim keybindings to JetBrains IDE actions.

**Key IDE action mappings:**
- Navigation: `]d`/`[d` for next/previous error, `gi` for go to implementation, `gr` for find usages
- Code actions: `<leader>ca` (show intentions), `<leader>cf` (reformat), `<leader>cr` (refactoring menu)
- Debugging: `<leader>t`/`<leader>T` (run), `<leader>d`/`<leader>D` (debug)

### Starship Configuration
Uses a custom Gruvbox Dark color palette with a multi-segment format. Each segment (os, directory, git, languages, time) has specific styling and positioning. The configuration detects multiple programming languages and shows their versions.

### rule-gof Configuration
Contains design pattern guidance for code generation tools:
- **`.copilot/instructions/gof.instructions.md`** - GitHub Copilot instruction file with Gang of Four patterns, SOLID principles, and OOP best practices. Applied to Python, Java, TypeScript, JavaScript, and C# files.
- **`.claude/rules/gof.md`** - Claude Code rule file auto-loaded for the same file types. Provides the same design pattern guidance when working in Claude Code.

Both files cover creational, structural, and behavioral patterns, with emphasis on composition over inheritance, loose coupling, and clean code practices.

**Installation note:** When stowing rule-gof, use `--no-folding` to create file-level symlinks: `stow --no-folding -t ~ rule-gof`. This allows other rules to coexist in `~/.claude/rules/` and `~/.copilot/instructions/`.

### rule-java Configuration
Contains Java style guidance for code generation tools:
- **`.copilot/instructions/java.instructions.md`** - GitHub Copilot instruction file with Sun Checkstyle conventions, JSpecify nullability, and JDK 21 idioms. Applied to Java files.
- **`.claude/rules/java.md`** - Claude Code rule file auto-loaded for Java files. Provides the same style guidance when working in Claude Code.

Both files cover naming conventions, import ordering, nullability annotations, the `final` keyword, and JDK 21 idioms (switch expressions, `var`, records, sealed classes, pattern matching, text blocks).

**Installation note:** When stowing rule-java, use `--no-folding` to create file-level symlinks: `stow --no-folding -t ~ rule-java`. This allows other rules to coexist in `~/.claude/rules/` and `~/.copilot/instructions/`.

### rule-maven Configuration
Contains Maven build conventions for code generation tools:
- **`.copilot/instructions/maven.instructions.md`** - GitHub Copilot instruction file with Maven command best practices: `-f` for module targeting, `-T 1C` for parallelism, and build cache flags. Applied to POM files and JVM language source files.
- **`.claude/rules/maven.md`** - Claude Code rule file auto-loaded for the same file types. Provides the same Maven build conventions when working in Claude Code.

Both files cover module targeting (using `-f` instead of `-pl`), parallel execution (`-T 1C`), disabling build cache (`-Dmaven.build.cache.enabled=false`), and output quality flags.

Applies to: `**/pom.xml`, `**/*.java`, `**/*.kt`, `**/*.kts`, `**/*.scala`, `**/*.groovy` — all common JVM language files where Maven builds are used.

**Installation note:** When stowing rule-maven, use `--no-folding` to create file-level symlinks: `stow --no-folding -t ~ rule-maven`. This allows other rules to coexist in `~/.claude/rules/` and `~/.copilot/instructions/`.

### skill-review-pr Configuration
Contains a user-invoked skill for code review using pure git:
- **`.claude/skills/review-pr/SKILL.md`** - Claude Code `/review-pr` slash command. Reviews a pull request or merge request by accepting a PR/MR number, fetching the remote ref using git, and comparing it against the current branch (or a specified base branch). Works with GitHub, GitLab, Gitea, Forgejo, and any git remote that exposes PR refs — no `gh` CLI required.
- **`.copilot/skills/review-pr/SKILL.md`** - GitHub Copilot agent-mode prompt with equivalent workflow.

Both files perform the same steps: fetch the PR branch via remote refs (tries GitHub/Gitea style first, then GitLab/Bitbucket), compute the merge base, collect commit list + diff stat + full diff, read changed files for full context, and output a structured review (summary, per-file analysis with concerns and suggestions, overall assessment).

**Installation note:** When stowing skill-review-pr, use `--no-folding` to create file-level symlinks: `stow --no-folding -t ~ skill-review-pr`. This allows other skills to coexist in `~/.claude/skills/` and `~/.copilot/skills/`.

## Important Configuration Details

### Vim Leader Key
- Leader key is space (`let mapleader = " "`)
- No timeout on leader key sequences (`set notimeout`)
- Applies to both Vim and IdeaVim configurations

### Vim Settings
- Tabs: 2 spaces, expanded tabs, no shift rounding
- Searching: case-insensitive by default, smart case matching, inline search
- Navigation: 5 lines scroll offset, relative line numbers, match highlighting
- `.sdkmanrc` files are treated as Java properties files (line 12)

### NERDTree Configuration
- File tree not hijacked by netrw (`NERDTreeHijackNetrw=0`)
- Keybindings:
  - `<C-n>` - Open NERDTree
  - `<C-t>` - Toggle NERDTree
  - `<C-f>` - Find current file in tree
  - `<leader>n` - Focus NERDTree window

## Working With These Configurations

### Testing Configuration Changes
- Vim: Test changes by reloading with `:source ~/.vimrc`
- IdeaVim: Changes typically take effect after IDE restart or manual plugin refresh
- Starship: Test with `starship prompt` or check the prompt in a new shell session

### Adding New Vim Plugins
1. Add plugin line in vim-plug block: `Plug 'author/plugin-name'`
2. Run `:PlugInstall` in Vim
3. Configure keybindings or settings below the plug#end() block
4. Both Vim and IdeaVim will load the plugin (IdeaVim has its own plugin selection)

### Modifying IdeaVim Mappings
- Reference available actions at https://jb.gg/abva4t
- Most IDE actions are mapped in comments showing the action name
- Some mappings are conditional (e.g., commented breakpoint toggle on line 40)

## External Documentation References
- Vim documentation: `:help` in Vim
- IdeaVim plugins: https://jb.gg/ideavim-plugins
- IdeaVim actions: https://jb.gg/abva4t
- Starship config: https://starship.rs/config-schema.json
- Gruvbox theme: https://github.com/morhetz/gruvbox
