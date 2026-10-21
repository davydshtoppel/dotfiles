# AGENTS.md

This file provides guidance to coding agents (Claude Code, GitHub Copilot, and others) when working with code in this repository.

## Overview

This is a personal dotfiles repository containing editor and shell configurations:
- **vim/.vimrc** - Vim editor configuration with plugins and keybindings
- **ideavim/.ideavimrc** - IdeaVim plugin configuration for JetBrains IDEs
- **starship/.config/starship.toml** - Starship shell prompt configuration
- **omz/.omzrc** - Oh My Zsh plugin list and shell setup
- **vscode/Library/Application Support/Code/User/settings.json** - VS Code user settings (macOS), including VSCodeVim config mirroring `.vimrc`
- **rule-java/.copilot/instructions/java.instructions.md** - GitHub Copilot instruction for Java style conventions
- **rule-java/.claude/rules/java.md** - Claude Code rule for Java style conventions
- **skill-explain-diff/.claude/skills/explain-diff/SKILL.md** - Claude Code `/explain-diff` skill for analyzing changes between branches
- **skill-explain-diff/.agents/skills/explain-diff/SKILL.md** - GitHub Copilot equivalent for branch diff analysis
- **skill-explain-pull-request/.claude/skills/explain-pull-request/SKILL.md** - Claude Code `/explain-pull-request` skill for analyzing a PR/MR by number
- **skill-explain-pull-request/.agents/skills/explain-pull-request/SKILL.md** - GitHub Copilot equivalent for PR analysis
- **skill-create-junit-test/.claude/skills/create-junit-test/SKILL.md** - Claude Code `/create-junit-test` skill for generating JUnit 5 tests
- **skill-create-junit-test/.agents/skills/create-junit-test/SKILL.md** - GitHub Copilot equivalent for JUnit test generation
- **fzf/.fzfrc** - FZF key bindings, preview options, and shell integration (`source <(fzf --zsh)`)
- **ltree/.local/bin/ltree** - Colorized `tree`-mimicking zsh script for the FZF Alt-C preview, for machines without Homebrew's `tree`
- **skill-software-factory/.claude/skills/software-factory/SKILL.md** + **skill-software-factory/.claude/agents/software-factory-*.md** - Claude Code `/software-factory` software factory: orchestrator skill + explorer/planner/implementer/reviewer subagents
- **skill-software-factory/.copilot/agents/software-factory*.agent.md** - GitHub Copilot equivalent: `software-factory` orchestrator custom agent + the same four subagents

## Architecture & Key Relationships

### Vim Configuration Structure
The Vim configuration uses vim-plug for plugin management. Plugins are declared in `.vimrc` with `call plug#begin()` and `call plug#end()` blocks. Currently includes:
- `vim-log-highlighting` - Syntax highlighting for log files
- `vim-highlightedyank` - Visual feedback when yanking text
- `vim-commentary` - Comment/uncomment operator
- `nerdtree` - File tree explorer
- `rainbow_csv` - CSV file syntax highlighting
- `fzf` + `fzf.vim` - Fuzzy finder (`:Rg`, `:Files`, `:Buffers`)
- `vim-which-key` - Keybinding hints popup
- `vim-gitgutter` - Git diff signs and hunk operations

### IdeaVim Relationship
The `.ideavimrc` sources `.vimrc` at the top (`source ~/.vimrc`), so they share Vim settings. IdeaVim then adds IDE-specific action mappings that map Vim keybindings to JetBrains IDE actions, and enables the `which-key` and `NERDTree` IdeaVim plugins (which must be installed in the IDE) plus `set ideajoin`.

**Key IDE action mappings:**
- Navigation: `]d`/`[d` for next/previous error, `gi` for go to implementation, `gr` for find usages
- Code actions: `<leader>ca` (show intentions), `<leader>cf` (reformat), `<leader>co` (optimize imports), `<leader>cg` (generate), `<leader>cr` (refactoring menu), `<leader>rn` (rename)
- Windows: `<C-n>` (select in project view), `<C-t>` (activate terminal)
- Debugging: `<leader>t`/`<leader>T` (run), `<leader>d`/`<leader>D` (debug)

### Starship Configuration
Uses a custom Gruvbox Dark color palette with a multi-segment format. Each segment (os, username, directory, git, languages, docker/conda/pixi context, time) has specific styling and positioning. The configuration detects multiple programming languages and shows their versions.

### rule-java Configuration
Contains Java design and style guidance for code generation tools (replaces the former `rule-gof`: the GoF catalog was dropped in favour of pragmatic design rules):
- **`.copilot/instructions/java.instructions.md`** - GitHub Copilot instruction file with pragmatic design rules, boundary validation, style conventions, JSpecify nullability, and JDK 25 idioms. Applied to Java files.
- **`.claude/rules/java.md`** - Claude Code rule file auto-loaded for Java files. Provides the same style guidance when working in Claude Code.

Both files cover design (idioms over patterns, reuse existing utilities, interfaces as test seams, rule of three), validation at entry points only, logging, import ordering, nullability annotations, the `final` keyword, and JDK 25 idioms (pattern-matching switch, records, sealed types, virtual threads, `ScopedValue`).

**Installation note:** When stowing rule-java, use `--no-folding` to create file-level symlinks: `stow --no-folding -t ~ rule-java`. This allows other rules to coexist in `~/.claude/rules/` and `~/.copilot/instructions/`.

### vscode Configuration
Contains VS Code user configuration for macOS:
- **`Library/Application Support/Code/User/settings.json`** - Gruvbox theme, editor options, VSCodeVim settings (space leader, `jj` → Esc, `<leader>c*`/`<leader>f*` mappings matching `.ideavimrc`), and language formatter settings.

Not shared on purpose: `mcp.json`, `chatLanguageModels.json`, workspace files, and all machine-local state in the `User/` directory (History, globalStorage, workspaceStorage, sync, profiles).

**Installation note:** `stow --no-folding -t ~ vscode` — `--no-folding` is required so `~/Library/Application Support/Code/User/` stays a real directory. Move any existing real `settings.json` away first, otherwise stow refuses.

### skill-explain-diff Configuration
Contains a user-invoked skill for analyzing code changes between two branches:
- **`.claude/skills/explain-diff/SKILL.md`** - Claude Code `/explain-diff` slash command. Takes a feature branch (required) and optional base branch (defaults to current branch). Uses pure git to compute the diff, then produces an overview, a Mermaid diagram of affected components, and a categorized analysis (design, performance, complexity, concurrency, clean code) with a final result verdict. Handles already-merged branches by detecting ancestry and using the merge commit's first parent as the effective base.
- **`.agents/skills/explain-diff/SKILL.md`** - GitHub Copilot (and other `.agents`-aware harnesses) skill with equivalent workflow.

All git commands use `git --no-pager` to prevent interactive pager prompts.

**Installation note:** When stowing skill-explain-diff, use `--no-folding` so `~/.claude/skills/` and `~/.agents/skills/` (where `npx skills` installs too) stay real directories (otherwise stow symlinks the whole directory into the repo and Claude Code writes its synced skills there): `stow --no-folding -t ~ skill-explain-diff`.

### skill-explain-pull-request Configuration
Contains a user-invoked skill for analyzing a pull request or merge request by number:
- **`.claude/skills/explain-pull-request/SKILL.md`** - Claude Code `/explain-pull-request` slash command. Accepts a PR/MR number and optional base branch. Fetches the PR source branch via remote refs (tries GitHub/Gitea, then Bitbucket Server, then GitLab), resolves the target branch, then delegates to the `explain-diff` skill via the Skill tool — no `gh` CLI required.
- **`.agents/skills/explain-pull-request/SKILL.md`** - GitHub Copilot (and other `.agents`-aware harnesses) skill with equivalent workflow.

Both files try three ref conventions in order: `refs/pull/${N}/head` (GitHub/Gitea/Forgejo), `refs/pull-requests/${N}/from` (Bitbucket Server/Data Center), `refs/merge-requests/${N}/head` (GitLab).

Merged PR handling: ancestry check detects merge-commit merges; `MERGE_COMMIT^1` is used as the effective base. Squash/rebase merges are unaffected (original commits are not ancestors). All fetch commands use `GIT_TERMINAL_PROMPT=0`; `git remote show` uses `-n` (no network access).

**Installation note:** When stowing skill-explain-pull-request, use `--no-folding` so `~/.claude/skills/` and `~/.agents/skills/` (where `npx skills` installs too) stay real directories (otherwise stow symlinks the whole directory into the repo and Claude Code writes its synced skills there): `stow --no-folding -t ~ skill-explain-pull-request`.

### skill-create-junit-test Configuration
Contains a user-invoked skill for generating, refactoring, and maintaining Java unit tests following comprehensive conventions. Use when writing new tests, refactoring existing tests, or for test maintenance when the code under test has evolved (constructor changed, API updated, tests broken after refactoring):
- **`.claude/skills/create-junit-test/SKILL.md`** - Claude Code `/create-junit-test` slash command. Generates or refactors Java unit tests following JUnit 5, AssertJ, Mockito, and best practices (AAA structure, @Nested organization, parameterized tests, soft assertions, no mocks for data classes, etc.).
- **`.agents/skills/create-junit-test/SKILL.md`** - GitHub Copilot (and other `.agents`-aware harnesses) skill with equivalent workflow.

Both files enforce:
- **JUnit 5 + AssertJ + Mockito** — detect availability, fallback gracefully
- **Test organization:** `@Nested` inner class per public method, `when<Condition>_then<Expectation>` method names, `@DisplayName` on all tests/nested classes
- **AAA structure:** Arrange / Act / Assert with blank-line separators; no control flow in tests
- **Mocking:** `@Mock` + `@ExtendWith(MockitoExtension.class)`; do NOT mock data classes; do NOT call `verify()` on stubbed methods (strict stubs handle that)
- **Assertions:** `assertThat(subject).returns(expectedValue, Subject::getField)` for field checks; `SoftAssertions.assertSoftly()` for multi-property assertions; `assertThatThrownBy()` for exceptions
- **Parameterization:** Replace loops/conditionals with `@ParameterizedTest` + `@CsvSource` / `@MethodSource` / `@ValueSource`
- **Test data:** Object mother pattern for complex domain objects; inline constructors for simple values
- **Coverage:** One assertion focus per test; test all branches (happy path, edges, errors, conditionals)

**Installation note:** When stowing skill-create-junit-test, use `--no-folding` so `~/.claude/skills/` and `~/.agents/skills/` (where `npx skills` installs too) stay real directories (otherwise stow symlinks the whole directory into the repo and Claude Code writes its synced skills there): `stow --no-folding -t ~ skill-create-junit-test`.

### omz Configuration
Contains portable Oh My Zsh plugin list:
- **`omz/.omzrc`** - If `~/.oh-my-zsh` exists (and `ZSH` is not already set), sets `ZSH`, an empty `ZSH_THEME` (the prompt is handled by Starship), and the `plugins` array, then sources `oh-my-zsh.sh`. Does nothing when Oh My Zsh is not installed. Manages all built-in and custom plugins (`zsh-autosuggestions`, `zsh-syntax-highlighting`) in one place; header comments list the clone commands for custom plugins.

After stowing, add to `.zshrc`:
```zsh
[ -f ~/.omzrc ] && source ~/.omzrc
```

**Installation note:** `stow -t ~ omz` — no `--no-folding` needed.

### fzf Configuration
Contains FZF shell integration and key binding options:
- **`fzf/.fzfrc`** - Sets `FZF_DEFAULT_OPTS` (`--style full`), `FZF_CTRL_R_OPTS` (Ctrl-Y copies the command via `pbcopy`), `FZF_CTRL_T_OPTS` (preview via `fzf-preview.sh`), `FZF_ALT_C_OPTS`, and runs `source <(fzf --zsh)` to activate key bindings. `FZF_ALT_C_OPTS` invokes `ltree -C {}`; see the `ltree` Configuration section below for the bundled replacement script this repo provides for machines without a real `tree` binary.

After stowing, add to `.zshrc`:
```zsh
[ -f ~/.fzfrc ] && source ~/.fzfrc
```
The guard makes the line safe on machines where fzf is not installed.

**Installation note:** `stow -t ~ fzf` — no `--no-folding` needed.

### ltree Configuration
Contains a self-contained zsh script that mimics enough of `tree`'s behavior to serve as a drop-in for `fzf`'s Alt-C preview on machines without `tree` installed (and where installing it via Homebrew is not an option):
- **`ltree/.local/bin/ltree`** - Recursive directory walker using zsh glob qualifiers (no `find` dependency). Prints Unicode box-drawing branches (`├──`, `└──`, `│`) and a final `N directories, M files` summary line, matching `tree`'s default output shape.

Supported flags: `-C` (colorize output — directories bold blue, executables bold green, symlinks cyan, broken symlinks red), `-a` (show dotfiles), `-d` (directories only), `-L <n>` (depth limit), `--dirsfirst` (list directories before files per level). Unrecognized flags are ignored rather than erroring. Traps `SIGPIPE` so it exits cleanly when truncated by `| head -200`. This is intentionally minimal — not a full `tree` reimplementation (no `-I`/`-P` filters, no `-h`/`-s` sizes, no `--gitignore`; symlinked directories are shown but never followed).

**Installation note:** `stow -t ~ ltree` — no `--no-folding` needed. Ensure `~/.local/bin` is on `PATH` (e.g. `export PATH="$HOME/.local/bin:$PATH"` in `.zshrc`) so `ltree` can be found.

### skill-software-factory Configuration
A stack-agnostic "software factory" that takes a JIRA key or a free-text task and runs it through explore → plan → **checkpoint 1** → implement → verify → review → **checkpoint 2** → commit/PR (or leave as is / abort-discard).
- **`.claude/skills/software-factory/SKILL.md`** - `/software-factory <JIRA-KEY | task> | resume [id]` orchestrator. It runs in the main thread (not forked) so it can spawn subagents and use AskUserQuestion. `disable-model-invocation: true`. Pinned to `model: sonnet`: routing needs no Opus.
- **`.claude/agents/software-factory-explorer.md`** (haiku), **`software-factory-planner.md`** (opus), **`software-factory-implementer.md`** (sonnet), **`software-factory-reviewer.md`** (opus) - the subagents.
- **`.copilot/agents/software-factory.agent.md`** - Copilot orchestrator. Same flow; the `agents:` allowlist names the four subagents. `tools` is omitted on purpose so project JIRA/PR MCP tools and skills stay available.
- **`.copilot/agents/software-factory-{explorer,planner,implementer,reviewer}.agent.md`** - Copilot subagents (`user-invocable: false`). Their bodies are identical to the Claude agents; only the frontmatter differs (Copilot CLI tool names, `model:` priority lists). `tools` uses the Copilot CLI's own names (`view`/`grep`/`glob`/`bash`/`create`/`edit`) because the IntelliJ plugin runs on the CLI; `create` is listed explicitly since the `edit` alias does not create new files (a planner with only `edit` cannot write `plan.md`).

**Design constraints (keep them when editing):**
- **Only the explorer reads the codebase broadly.** The planner opens only the files named in the digest. The orchestrator passes file paths, not file contents.
- **Handoffs are size-capped files** in `<project>/.software-factory/runs/<id>/`: `task.md`, `digest.md` ≤150 lines, `plan.md` ≤200, `plan-amendment-N.md` ≤80, `impl-report.md` ≤60, `review.md` ≤60, `review.diff` (orchestrator-built, never read by it), `full.log`, `state.md`, `verify.log`, `baseline.log`, `self-check.log` (implementer's own check output, tail only), `usage.md` (orchestrator-written ledger: one row per subagent spawn with mode (incl. fix cause, retry, continuation), outcome (`ok`/`deviation`/`invalid`), configured model, tokens and tool uses from the result's `<usage>` block, and duration measured by the orchestrator (`date +%s` before and after every spawn, retry and continuation, mandatory), plus one row per baseline/verify+lint/full command run with pass/fail/timeout and duration; the end-of-run report shows per-agent totals, retry/deviation/fix counts and the command runs; tokens are approximate; on Copilot, rows carry the configured model and an orchestrator-measured duration, tokens and tool uses are `n/a`, see `/usage`), and `superseded/` (amendments retired by a re-plan). The orchestrator checks each file's existence, line cap and required headings after every subagent. It uses the Read result when it reads the file anyway, else one `wc -l` and one `Grep -c`. `.software-factory/` is added to `.git/info/exclude`, never to `.gitignore`.
- **No per-project config.** The explorer detects one verify command (from project docs → CI config → build files) plus the commit/branch conventions. You approve the verify command at checkpoint 1, and the orchestrator runs it itself; it never trusts the implementer's self-check. JIRA and PR tooling come from whatever the session has (project skills or MCP, else `gh`/`glab`, else a compare URL).
- **Loops.** The implementer stops with a `DEVIATION` instead of improvising, and the planner answers with a delta amendment. `amendments` ≤2 per run, shared with verify escalations (1st failure → implementer fix, 2nd → planner diagnose, 3rd → stop). Caps hand control back to you. The `amendments` count is derived from the `# Amendment <N> (amend|diagnose)` files on disk before each planner call (not kept in the model's memory), `state.md` is written once and then updated field by field with Edit after every subagent return (the three loop counters share one `counters:` line), and a deviation on a step an earlier amendment already replaced (or with the same cause) goes straight to the deviation checkpoint. To avoid one-mismatch-per-round ping-pong, the implementer runs a preflight over all remaining steps before editing and reports every deviation at once (minor mismatches inside planned files are Adaptations, not deviations), and the planner's `amend` mode fixes the whole class of the wrong assumption in one amendment. Amendment numbers come from the files on disk, user-requested work (`revise` planner mode) never counts against the caps and resets `verify_failures`, and a verify run on the fresh branch (baseline) keeps pre-existing failures from burning the fix budget. Files the worktree already had changed are recorded as `preexisting_dirty` and never staged.
- **Gates before verify.** After the implementer finishes, the orchestrator checks with plain git/grep (no model cost): changed paths ⊆ planned paths, every planned test exists, no test removed or skipped (test diff read with `-U0`). A miss counts as a verify failure and goes to the implementer `fix`. Every AC is mapped to a test case (`AC` column); for `Type: fix` the regression test must fail before the fix.
- **Plan gate.** Before checkpoint 1 (and on amended steps after an amendment) the orchestrator checks with Glob/Grep: `modify`/`delete` paths exist, `new` paths do not, every AC appears in the test table; signature identifiers missing from their file are warnings. A miss reruns the planner once. This is the cheap stand-in for a plan-reviewer; checkpoint 1 is the human plan review.
- **Lint and full suite.** The plan's `Lint:` is stored as `lint_cmd` and runs after `verify_cmd` (a lint failure is a verify failure). `full_cmd` runs once before a push (`full.log`); on failure the user picks fix / push anyway / commit only.
- **Review (Phase 4.5).** After verify passes, the orchestrator writes `review.diff` (tracked diff vs base plus untracked files, never read by it) and spawns the Opus reviewer once per run. The reviewer reads the diff, the plan and the digest's idioms/rules sections only, and writes `review.md` (verdict + findings table, ≤60 lines). `CHANGES` (≥1 blocker/major) gives one implementer `fix`, then gates and verify, and no second review (`review_rounds` ≤1). Review fixes never count against `amendments`.
- **Continue, don't respawn (Claude only).** A `fix` right after an implementer run goes to the same agent via `SendMessage`, so it keeps plan, digest and files in context; fresh spawn as a fallback. Copilot spawns fresh.
- **Style.** Pragmatic simplified technical English (STE) in all factory files and in user messages: one instruction per sentence, one word per concept, tables over prose, a procedure defined once and referred to by name. The Claude and Copilot bodies stay identical except for platform spots (frontmatter, subagent table "Role" column, checkpoints section, `INPUT`/`$ARGUMENTS`, SendMessage continuation, `?`/`n/a` in the ledger, timeout wording). Copilot subagent bodies are copied 1:1 from the Claude ones.
- **Cost rules.** Explorer and planner have Edit and update their files in place (never rewrite). Plan/amendment caps are limits, not targets. The planner reads digest line ranges only, with ≤5 targeted Grep/Glob for digest gaps. Implementers redirect build output to a log and read only its tail. They read only the digest sections Tests, Idioms & conventions and Project rules, and do not re-read plan, digest or edited files on a continued `fix`. Planner and reviewer confirm signatures with `Grep -n`. Subagent replies are one fixed-form line plus open items (≤5 lines).
- **Planner design rules.** Idioms first. A design pattern needs a justification, the rejected simpler alternative, and ≥2 concrete variants or a real extension point. It keeps its own design rules, independent of `rule-java`.
- **Checkpoint 2 exits.** Commit+push+PR / commit only / leave as is (uncommitted, `phase: done`) / abort (discard: restore tracked, remove untracked by explicit path, never `preexisting_dirty`, switch to base, `git branch -d`). Request changes is the free-text answer (4-option limit of AskUserQuestion).
- **Backlog (reviewed, deliberately not built):** per-repo facts cache (`.software-factory/project.md`), size triage (S-tasks on a cheaper planner).
- **Not in the MVP yet:** plan-reviewer (an Opus pass over `plan.md` before checkpoint 1), size triage, and a commit guard hook. Commit, push and PR rely on checkpoint 2 plus platform approval prompts.

**Installation note:** `stow --no-folding -t ~ skill-software-factory`. `--no-folding` keeps `~/.claude/agents`, `~/.claude/skills` and `~/.copilot/agents` as real directories.

## Important Configuration Details

### Vim Leader Key
- Leader key is space (`let mapleader = " "`)
- Timeout on key sequences: 500 ms (`set timeout timeoutlen=500`)
- `jj` in insert mode → `<Esc>` (`inoremap jj <Esc>`)
- Applies to both Vim and IdeaVim configurations

### Vim Settings
- Tabs: 2 spaces, expanded tabs, no shift rounding
- Searching: case-insensitive by default, smart case matching, inline search
- Navigation: 5 lines scroll offset, relative line numbers, match highlighting
- `.sdkmanrc` files are treated as Java properties files; `.fzfrc` files as shell (`sh`)

### NERDTree Configuration
- File tree not hijacked by netrw (`NERDTreeHijackNetrw=0`)
- Keybindings:
  - `<C-n>` - Open NERDTree
  - `<C-t>` - Toggle NERDTree
  - `<C-f>` - Find current file in tree
  - `<leader>n` - Focus NERDTree window
- Hidden files shown (`NERDTreeShowHidden=1`)

### Other Vim Keybindings
- `<leader>h` - Clear search highlight
- FZF: `<leader>r` (ripgrep), `<C-p>` (files), `<C-b>` (buffers)
- GitGutter: `<leader>gp`/`gs`/`gu` (preview/stage/undo hunk), `<leader>gn`/`gP` (next/previous hunk)
- which-key: `<leader>?` shows keybindings; descriptions live in `g:which_key_map` — update it when adding mappings

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
- Some mappings are commented out (e.g., breakpoint toggle `\b`)

## Repository Conventions
- Each top-level directory is a stow package; its internal layout mirrors the target path under `~`.
- Rules and skills exist in paired Claude Code (`.claude/`) and GitHub Copilot variants (`.copilot/instructions/` for rules, `.agents/skills/` for skills) — keep both in sync when changing either.
- When adding or changing a package, update `README.md` (contents, stow commands, symlink list) and this file.
- Do not commit `skill-create-junit-test/.claude/skills/synced/` — it is generated by Claude tooling.

## External Documentation References
- Vim documentation: `:help` in Vim
- IdeaVim plugins: https://jb.gg/ideavim-plugins
- IdeaVim actions: https://jb.gg/abva4t
- Starship config: https://starship.rs/config-schema.json
- Gruvbox theme: https://github.com/morhetz/gruvbox
