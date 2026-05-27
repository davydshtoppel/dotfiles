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
- **skill-explain-diff/.claude/skills/explain-diff/SKILL.md** - Claude Code `/explain-diff` skill for analyzing changes between branches
- **skill-explain-diff/.copilot/skills/explain-diff/SKILL.md** - GitHub Copilot equivalent for branch diff analysis
- **skill-explain-pull-request/.claude/skills/explain-pull-request/SKILL.md** - Claude Code `/explain-pull-request` skill for analyzing a PR/MR by number
- **skill-explain-pull-request/.copilot/skills/explain-pull-request/SKILL.md** - GitHub Copilot equivalent for PR analysis
- **skill-create-junit-test/.claude/skills/create-junit-test/SKILL.md** - Claude Code `/create-junit-test` skill for generating JUnit 5 tests
- **skill-create-junit-test/.copilot/skills/create-junit-test/SKILL.md** - GitHub Copilot equivalent for JUnit test generation

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

### skill-explain-diff Configuration
Contains a user-invoked skill for analyzing code changes between two branches:
- **`.claude/skills/explain-diff/SKILL.md`** - Claude Code `/explain-diff` slash command. Takes a feature branch (required) and optional base branch (defaults to current branch). Uses pure git to compute the diff, then produces an overview, a Mermaid diagram of affected components, and a categorized analysis (design, performance, complexity, concurrency, clean code) with a final result verdict.
- **`.copilot/skills/explain-diff/SKILL.md`** - GitHub Copilot agent-mode prompt with equivalent workflow.

**Installation note:** When stowing skill-explain-diff, no `--no-folding` is needed — the `explain-diff/` subdirectory prevents stow from folding: `stow -t ~ skill-explain-diff`.

### skill-explain-pull-request Configuration
Contains a user-invoked skill for analyzing a pull request or merge request by number:
- **`.claude/skills/explain-pull-request/SKILL.md`** - Claude Code `/explain-pull-request` slash command. Accepts a PR/MR number and optional base branch. Fetches the PR source branch via remote refs (tries GitHub/Gitea, then Bitbucket Server, then GitLab), resolves the target branch, and produces the same structured analysis as `explain-diff` — no `gh` CLI required.
- **`.copilot/skills/explain-pull-request/SKILL.md`** - GitHub Copilot agent-mode prompt with equivalent workflow.

Both files try three ref conventions in order: `refs/pull/${N}/head` (GitHub/Gitea/Forgejo), `refs/pull-requests/${N}/from` (Bitbucket Server/Data Center), `refs/merge-requests/${N}/head` (GitLab).

**Installation note:** When stowing skill-explain-pull-request, no `--no-folding` is needed — the `explain-pull-request/` subdirectory prevents stow from folding: `stow -t ~ skill-explain-pull-request`.

### skill-create-junit-test Configuration
Contains a user-invoked skill for generating and refactoring Java unit tests following comprehensive conventions:
- **`.claude/skills/create-junit-test/SKILL.md`** - Claude Code `/create-junit-test` slash command. Generates or refactors Java unit tests following JUnit 5, AssertJ, Mockito, and best practices (AAA structure, @Nested organization, parameterized tests, soft assertions, no mocks for data classes, etc.).
- **`.copilot/skills/create-junit-test/SKILL.md`** - GitHub Copilot agent-mode prompt with equivalent workflow.

Both files enforce:
- **JUnit 5 + AssertJ + Mockito** — detect availability, fallback gracefully
- **Test organization:** `@Nested` inner class per public method, `when<Condition>_then<Expectation>` method names, `@DisplayName` on all tests/nested classes
- **AAA structure:** Arrange / Act / Assert with blank-line separators; no control flow in tests
- **Mocking:** `@Mock` + `@ExtendWith(MockitoExtension.class)`; do NOT mock data classes; do NOT call `verify()` on stubbed methods (strict stubs handle that)
- **Assertions:** `assertThat(subject).returns(expectedValue, Subject::getField)` for field checks; `SoftAssertions.assertSoftly()` for multi-property assertions; `assertThatThrownBy()` for exceptions
- **Parameterization:** Replace loops/conditionals with `@ParameterizedTest` + `@CsvSource` / `@MethodSource` / `@ValueSource`
- **Test data:** Object mother pattern for complex domain objects; inline constructors for simple values
- **Coverage:** One assertion focus per test; test all branches (happy path, edges, errors, conditionals)

**Installation note:** When stowing skill-create-junit-test, no `--no-folding` is needed — the parent directory `create-junit-test/` prevents stow from folding: `stow -t ~ skill-create-junit-test`.

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
