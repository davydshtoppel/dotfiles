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
- **skill-atelier/.claude/skills/atelier/SKILL.md** + **skill-atelier/.claude/agents/atelier-*.md** - Claude Code `/atelier` atelier: orchestrator skill + explorer/planner/implementer/reviewer subagents
- **skill-atelier/.copilot/agents/atelier*.agent.md** - GitHub Copilot equivalent: `atelier` orchestrator custom agent + the same four subagents
- **skill-atelier/.local/bin/atelier** - bash script with the atelier's deterministic bookkeeping; **skill-atelier/tests/atelier.test.sh** - its smoke test

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

### skill-atelier Configuration
A stack-agnostic "atelier" (Opus-level code quality for fewer tokens: strong models plan and review, cheaper models explore and implement) that takes any coding task and runs it through explore → plan → **checkpoint 1** → implement → verify → review → **checkpoint 2** → accept (changes stay uncommitted) or abort-discard. It knows nothing about tickets, branches, commits or PRs: other skills (for example a git-workflow skill) handle those, and the atelier works on the current worktree.
- **`.claude/skills/atelier/SKILL.md`** - `/atelier <task> | resume [id]` orchestrator. It runs in the main thread (not forked) so it can spawn subagents and use AskUserQuestion. `disable-model-invocation: true`. Pinned to `model: sonnet`: routing needs no Opus.
- **`.claude/agents/atelier-explorer.md`** (haiku), **`atelier-planner.md`** (opus), **`atelier-implementer.md`** (sonnet), **`atelier-reviewer.md`** (opus) - the subagents.
- **`.copilot/agents/atelier.agent.md`** - Copilot orchestrator. Same flow; the `agents:` allowlist names the four subagents. `tools` is omitted on purpose so project MCP tools and skills stay available.
- **`.copilot/agents/atelier-{explorer,planner,implementer,reviewer}.agent.md`** - Copilot subagents (`user-invocable: false`). Their bodies are identical to the Claude agents; only the frontmatter differs (Copilot CLI tool names, `model:` priority lists). `tools` uses the Copilot CLI's own names (`view`/`grep`/`glob`/`bash`/`create`/`edit`) because the IntelliJ plugin runs on the CLI; `create` is listed explicitly since the `edit` alias does not create new files (a planner with only `edit` cannot write `plan.md`). All four subagents use the same list, `['view', 'grep', 'glob', 'bash', 'edit', 'create']`: the CLI asked for extra permissions when planner and reviewer lacked `bash`, and `edit` comes before `create` in case the order matters.
- **`.local/bin/atelier`** - bash script (macOS bash 3.2 compatible) called by both orchestrators as `atelier <subcommand> <run-id> ...`. Subcommands: `init`, `dirty`, `state`, `clock`, `start`, `log`, `run`, `validate`, `amendments`, `plan-gate`, `gates`, `changed`, `preexisting`, `snapshot`, `review-diff`, `recheck-diff`, `report`. First output line is `key=value` pairs, then max 20 finding lines. Exit 0 = pass, 1 = miss or fail, 2 = usage error, 124 = timeout.
- **`tests/atelier.test.sh`** - smoke test: builds a temp git repo with a fake run and checks the exit code and first line of each subcommand. Run it with `/bin/bash` after every script change. `.stow-local-ignore` keeps `tests/` out of the symlinks.

**Design constraints (keep them when editing):**
- **The script owns the deterministic steps.** Exit codes, not model judgement, decide pass/fail. Caps, required headings, gate rules and the weakened-test patterns live only in the script. The skill text names the subcommand and the routing on its result. `run` takes the verify, lint and full commands from `state.md` (approved at checkpoint 1) and enforces a time limit (570 s, `ATELIER_TIMEOUT`) below the Bash tool limit. `run full` has its own limit (3600 s, `ATELIER_FULL_TIMEOUT`); Claude starts it in the background, Copilot sets it to 570 s. The planner writes amendment steps as `- replace|add step <k> — <path> (<kind>)` and test rows in the plan's table form because `gates` and `plan-gate` parse them.
- **The orchestrator never does subagent work.** The **Delegation** rules forbid reading project source and editing outside `.atelier/`. Phase 0 step 0 (preflight) stops the run if no subagent tool exists. `atelier validate` checks for a `usage.md` row before it accepts a handoff file, so a file the orchestrator wrote itself is caught. The Copilot orchestrator keeps all tools on purpose (MCP tools, `bash`), so these are prompt rules. Fallback if they fail: a Copilot `preToolUse` hook that denies `edit`/`create` outside `.atelier/`.
- **Only the explorer reads the codebase broadly.** The planner opens only files named in the digest. The orchestrator passes paths, not contents.
- **Handoffs are size-capped files** in `<project>/.atelier/runs/<id>/`. Caps and required headings are in the script (`validate`). Others: `task.md`, `review.diff`/`recheck.diff` (orchestrator-built, never read by it), `snap.index`, `*.log`, `state.md`, `usage.md`, `superseded/`. The orchestrator runs `atelier validate` after every subagent. `.atelier/` goes to `.git/info/exclude`, never `.gitignore`.
- **Usage ledger.** `usage.md` has one row per subagent spawn (mode, outcome, configured model, tokens, tool uses, orchestrator-measured duration) and one row per baseline/verify+lint/full command. `log` and `run` write the rows; `validate` marks the row of a failed file `invalid`. Tokens are approximate. On Copilot, tokens and tool uses are `n/a`; see `/usage`.
- **No per-project config.** The explorer detects the verify command. You approve the verify command at checkpoint 1. The orchestrator runs it itself and never trusts the implementer's self-check.
- **Loops.** The implementer stops with a `DEVIATION` instead of improvising. The planner answers with a delta amendment. Caps are in the skill's Loop caps table and hand control back to you. The `amendments` count comes from the files on disk, not from model memory. `state.md` is written once, then updated field by field. A repeat deviation goes straight to the deviation checkpoint. The implementer preflights all remaining steps and reports every deviation at once. The planner's `amend` fixes the whole class of a wrong assumption. User-requested work (`revise`) never counts against the caps. A baseline verify on the fresh branch keeps pre-existing failures from burning the fix budget. Files the worktree already had changed are `preexisting_dirty` and never staged. `atelier dirty` records them per file (`-uall`); an entry that ends in `/` also matches the files under it. Every implementer run sets `phase=implement`, so `resume` after a crash runs gates and verify before review or recheck. There is no general planner → explorer loop (an Opus restart costs more than 5 targeted Grep/Glob calls). The one exception is **Re-plan from scratch**: the explorer runs once in `mode: refresh` and adds `## Corrections` to the digest; the planner reads it first.
- **Gates before verify** (plain git/grep, no model cost): changed paths ⊆ planned paths, planned tests exist, no test removed or skipped (`atelier gates`; a modify-step or test-table file that exists in `HEAD` may remove test lines only if it adds at least as many; a new test file is scanned whole for skip markers; a skip marker is always a miss; files under `__snapshots__/` next to a planned test file are in scope). A miss counts as a verify failure. Every AC maps to a test case. For `Type: fix` the regression test must fail before the fix.
- **Plan gate** (`atelier plan-gate`) before checkpoint 1: `modify`/`delete` paths exist, `new` paths do not, every AC is in the test table, `## Verify` has a command or `none`. A step path in `preexisting_dirty` is a warning. A miss reruns the planner once. It also sets `verify_cmd`, `full_cmd` and `lint_cmd` from the plan's `## Verify`. It is the cheap stand-in for a plan-reviewer; checkpoint 1 is the human plan review.
- **Lint and full suite.** `lint_cmd` runs after `verify_cmd`; a lint failure is a verify failure. `full_cmd` runs once on accept; on failure you pick fix / accept anyway.
- **Review (Phase 4.5).** The Opus reviewer runs once per run on `review.diff` and writes `review.md`. `CHANGES` gives one implementer `fix`, gates, verify, then one focused recheck (Phase 4.6) on `recheck.diff`, the diff between two temporary-index tree snapshots. Recheck `CHANGES` starts no second fix; open rows go to checkpoint 2. Review fixes never count against `amendments`; a DEVIATION during a review fix counts like any deviation.
- **Continue, don't respawn (Claude only).** A `fix` right after an implementer run goes to the same agent via `SendMessage`. The preflight loads `SendMessage` with ToolSearch when it is deferred. Fresh spawn as a fallback. Copilot spawns fresh.
- **Background subagents (Claude).** The orchestrator waits for the completion notification before `log` and `validate`, and runs one subagent at a time.
- **Style.** Simplified technical English (STE) in all atelier files and user messages: one instruction per sentence, one word per concept, tables over prose, a procedure defined once and referred to by name. Claude and Copilot bodies stay identical except platform spots (frontmatter, "Role" column, checkpoints section, `INPUT`/`$ARGUMENTS`, SendMessage continuation, ledger `?`/`n/a`, timeout wording). Copilot subagent bodies are copied 1:1 from the Claude ones.
- **Cost rules.** Explorer and planner update their files in place with Edit. Caps are limits, not targets. The planner reads digest line ranges only. Implementers redirect build output to a log and read its tail. They read only the digest sections Tests, Idioms & conventions and Project rules. Subagent replies are one fixed-form line plus open items (≤5 lines).
- **Planner design rules.** Idioms first. A design pattern needs a justification, the rejected simpler alternative, and ≥2 concrete variants or a real extension point. These rules are independent of `rule-java`.
- **Checkpoint 2 exits.** Accept / abort (discard: restore tracked, remove untracked by explicit path, never `preexisting_dirty`). Request changes is the free-text answer (AskUserQuestion allows 4 options).
- **Implement loop.** One named procedure in the orchestrator: validate `impl-report.md` → gates → verify. Every route that runs the implementer ends in it. A verify failure is counted once, where it is found (gate miss, or non-pre-existing Phase 4 failure); the failure table only routes. `validate` accepts one handoff file per subagent row (keyed by agent, not file name), so a file the orchestrator wrote after a valid one is caught, also under a new name such as the next amendment. Ledger modes have no spaces (`fix:verify`, `fix:verify:cont`, `plan:retry`).
- **Known heuristic limits (accepted):** the weakened-test gate does not see changed expected values; the skip patterns miss `xtest(`, `it.todo`, `xfail` and `assume*`; a red baseline can hide that new tests never ran; a rename checks only the new path; a planned test name found in a comment satisfies the tests gate; `preexisting` normalizes digits, so a summary line (`Tests run: N, Failures: N`) always matches the baseline and only per-test error lines decide.
- **Backlog (reviewed, deliberately not built):** per-repo facts cache (`.atelier/project.md`), size triage (S-tasks on a cheaper planner).
- **Not in the MVP yet:** plan-reviewer (Opus pass over `plan.md` before checkpoint 1), size triage, commit guard hook. Commit, push and PR rely on checkpoint 2 plus platform approval prompts.

**Installation note:** `stow --no-folding -t ~ skill-atelier`. `--no-folding` keeps `~/.claude/agents`, `~/.claude/skills` and `~/.copilot/agents` as real directories. The script links to `~/.local/bin/atelier`: put `~/.local/bin` on `PATH`. The preflight stops a run if the script is missing.

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
