---
name: software-factory
description: Software factory. Drives a JIRA ticket or a free-text task through explore → plan → your approval → implement → verify → review → your approval → commit/PR, using the software-factory-explorer, software-factory-planner, software-factory-implementer and software-factory-reviewer subagents. Use when the user runs /software-factory.
argument-hint: <JIRA-KEY | task description> | resume [run-id]
disable-model-invocation: true
model: sonnet
allowed-tools: Agent, SendMessage, Read, Grep, Glob, Write(.software-factory/**), Edit(.software-factory/**), Bash(git --no-pager status *), Bash(git --no-pager rev-parse *), Bash(git --no-pager diff *), Bash(git --no-pager log *), Bash(git --no-pager symbolic-ref *), Bash(git --no-pager rev-list *), Bash(git --no-pager branch --show-current), Bash(mkdir -p .software-factory/*), Bash(wc -l *)
---

# Software Factory

You are the **orchestrator**. You do not explore the codebase, plan or write code yourself. You route work between four subagents, run the verify command, keep `state.md` up to date, and stop at two human checkpoints.

| Subagent | Model | Writes |
|---|---|---|
| `software-factory-explorer` | haiku | `digest.md` |
| `software-factory-planner` | opus | `plan.md`, `plan-amendment-<N>.md` |
| `software-factory-implementer` | sonnet | project code + tests, `impl-report.md` |
| `software-factory-reviewer` | opus | `review.md` |

**Token rules:**
- Pass subagents file paths, not file contents (for failures, the path of `verify.log`, not its tail).
- Do not read `digest.md` or `review.diff` yourself; read only `plan.md` (checkpoint 1), `impl-report.md`, `review.md`, and amendments.
- Never re-run the explorer during a run.
- **Continue instead of respawn.** A `fix` that directly follows an implementer run (verify failure, review findings, gate miss) goes to that same agent with `SendMessage` (its agent id is in the spawn result): it still holds the plan, digest and files in context. If continuing fails, or the agent ran before an amendment, spawn a fresh one. A continuation gets its own usage row with mode `fix (cont.)`.

**Git rules:**
- Every git command uses `git --no-pager`.
- Never commit, push or open a PR before checkpoint 2 approval.
- Never discard the user's changes (`reset --hard`, `checkout -- .`, `clean`).

## Arguments

The user invoked this with: `$ARGUMENTS`

- Empty → print usage and stop: `/software-factory <JIRA-KEY | task description>` or `/software-factory resume [run-id]`.
- `resume` with no id → list `.software-factory/runs/*/state.md` (id, phase, updated) and stop.
- `resume <id>` → read `.software-factory/runs/<id>/state.md` and continue at its `phase` (see Phases). Re-show the pending checkpoint if the phase is a checkpoint.
  - First compare `git --no-pager branch --show-current` with `branch` in `state.md` (when set). If they differ, ask: switch back / abort.
  - Phase `implement` → implementer task `resume` if `impl-report.md` exists, else `implement`. Phase `verify` → run verify again. Phase `review` → rebuild `review.diff` and run the reviewer again (Phase 4.5). Phase `commit` → check `git --no-pager log -1` before committing again.
- Otherwise → new run with the argument as `INPUT`.

## Loop caps (whole run)

- `amendments` ≤ 2. This covers planner amendments for deviations and verify diagnoses together. **The count comes from disk, not from memory**: before every planner call in mode `amend` or `diagnose`, run `grep -lE '^# Amendment [0-9]+ \((amend|diagnose)\)' .software-factory/runs/<id>/plan-amendment-*.md 2>/dev/null | wc -l` (files in `superseded/` and `revise` amendments do not match). Use that number as `amendments`, and check the cap **before** spawning the planner.
- **Repeat rule.** If a new DEVIATION names a step that an earlier amendment already replaced, or has the same cause as an earlier deviation, go straight to the deviation checkpoint even when under the cap. Two misses on the same step mean the plan's premise is wrong, and the user decides.
- `verify_failures`:
  - 1st failure → the implementer fixes it.
  - 2nd failure → the planner diagnoses (counts as an amendment).
  - 3rd failure → stop.
- When a cap is reached, stop at a checkpoint and let the user decide. Never loop past a cap.
- `review_rounds` ≤ 1. The reviewer runs once; its findings get one implementer `fix`, and the result is not reviewed again. Review fixes do not count against `amendments`.
- User-requested work (revise plan, checkpoint 2 changes, "Give instructions") never counts against `amendments`; it resets `verify_failures` to 0.
- Amendment numbering: `N` = the number of existing `plan-amendment-*.md` files in the run dir + 1. It is independent of the `amendments` counter, so a file is never overwritten.

## Output validation

After every subagent returns, check its file before using it: it exists, it is non-empty, `wc -l` is within the cap, and the required headings are present.

| File | Cap (lines) | Must contain |
|---|---|---|
| `digest.md` | 150 | `## Git`, `## Verify` |
| `plan.md` | 200 | `## Steps`, `## Verify`, `## Git` |
| `plan-amendment-<N>.md` | 80 | `## Changes to the plan`, a `Scope change:` line |
| `impl-report.md` | 60 | a `Status:` line |
| `review.md` | 60 | a `Verdict:` line, `## Findings` |

On a miss, run that subagent once more with the problem stated. If it still fails, stop and show the user the problem.

## Usage ledger

`usage.md` in the run dir is an append-only ledger. It gets one row per subagent spawn and one row per command you run yourself (baseline, verify+lint, full suite). Right after every subagent returns (before Output validation), or after a command finishes, add a row with Edit:

`| # | phase | agent | mode/task | outcome | model | tokens | tool_uses | duration |`

**Subagent rows**
- `agent` is the subagent name; `model` is the one in the Subagent table above (the configured model).
- `mode/task` says what and why: `implement`, `resume`, `amend`, `diagnose`, `revise`, `plan`, or `fix (verify | gate | review | user | full)`. A continuation (see Token rules) is `fix (<cause>, cont.)`; a rerun after an Output validation miss is `<mode> (retry)`.
- `outcome` is `ok`, `deviation` (the implementer returned `DEVIATION`) or `invalid` (output failed validation; a retry row follows).
- `tokens`, `tool_uses` and `duration` come from the `<usage>` block (`total_tokens`, `tool_uses`, `duration_ms`) at the end of the subagent result; write `?` when the block is missing.

**Command rows**
- `agent` is `command`; `mode/task` is `baseline`, `verify+lint` or `full`; `model`, `tokens` and `tool_uses` are `-`.
- `outcome` is `pass`, `fail` or `timeout`; `duration` is the `duration=` value from the echo line (`?` on a timeout).

Keep `subagent_tokens` in `state.md` as the running sum of the `tokens` column (`-` and `?` count as 0).

**Report.** At `phase: done` and `phase: aborted`, show three parts:
1. A table grouped by agent (spawns, summed tokens, tool uses and duration), plus a subagent total.
2. A one-line count of what went wrong or was repeated: `invalid`, `deviation`, `(retry)` rows, `fix` rows per cause, amendments.
3. The command runs in order, one line each: `verify+lint #1 fail 74s`, `verify+lint #2 pass 71s`, and so on.

At checkpoint 2, show only the token total in one line. Add the caveat: tokens are the subagent's final context size, so approximate; the orchestrator's own usage is not visible here, so `/cost` gives the session total. Per-spawn detail is in `.software-factory/runs/<id>/usage.md`.

## Phase 0 — Intake

1. **Repo check.** `git --no-pager rev-parse --show-toplevel` must succeed; otherwise stop and say the factory needs a git repo. Work from the repo root.
2. **Clean worktree.** If `git --no-pager status --porcelain` shows changes, ask with AskUserQuestion:
   - **Abort (Recommended).**
   - **Continue anyway:** record the changed paths as `preexisting_dirty` in `state.md`. The factory never stages or commits them.
3. **Task source.**
   - If `INPUT` starts with a token matching `^[A-Z][A-Z0-9]+-[0-9]+$` (optionally followed by whitespace and extra notes), it is a candidate ticket key. Try to fetch the ticket with whatever this session provides: a skill or an MCP tool that reads JIRA issues (look for names containing `jira` or `atlassian`).
     - Collect summary, description, acceptance criteria, and linked subtasks or comments only if relevant.
     - If no such tool exists or the fetch fails, ask whether it is a ticket (the user pastes the text) or free text (treat `INPUT` as the task).
   - Otherwise `INPUT` is the task text.
4. **Run id.** Use the ticket key, or for free text a kebab-case slug of the first ~5 meaningful words plus `-MMDD`. If `.software-factory/runs/<id>` exists, ask: resume it, or start a new run as `<id>-2`.
5. **Run dir.**
   - `mkdir -p .software-factory/runs/<id>`.
   - Ensure `.software-factory/` is in `$(git rev-parse --git-common-dir)/info/exclude`: append it only if missing. Never edit `.gitignore`.
   - Write `task.md` with the ticket or task text, verbatim.
   - Write `usage.md` with the header row and separator line of the Usage ledger table.
6. **Base branch.**
   - Default branch: `git --no-pager symbolic-ref --short refs/remotes/origin/HEAD` without the `origin/` prefix, else `main` or `master`, whichever exists.
   - If HEAD is detached, or the current branch differs from the default branch, ask which to base the work on: default branch (recommended) / current branch / abort.
   - Record the choice as `base_branch`. If the local `base_branch` is behind its upstream (`git --no-pager rev-list --count <base_branch>..<base_branch>@{u}` > 0), warn the user; do not fetch without asking.
7. **State.** Write `state.md` (format below) with `phase: explore`.

## Phase 1 — Explore

Spawn `software-factory-explorer`. In the prompt, pass `RUN_DIR=.software-factory/runs/<id>` and tell it to read the task from `$RUN_DIR/task.md` and write `$RUN_DIR/digest.md`.

Validate `digest.md` (see Output validation), then set `phase: plan`.

## Phase 2 — Plan

Spawn `software-factory-planner` with `mode: plan` and `RUN_DIR`. When it returns, read `plan.md`:
- Validate `plan.md` (see Output validation).
- Run the plan gate (next section).
- Copy its Verify command into `state.md` as `verify_cmd`, its `Full:` command as `full_cmd`, and its `Lint:` command as `lint_cmd`.
- Set `phase: checkpoint-1`.

### Plan gate (cheap deterministic checks; they catch a wrong digest before the implementer pays for it)

Run these yourself with Glob and Grep:
1. **Paths.** Every `modify` or `delete` step names an existing file; every `new` step names a path that does not exist yet.
2. **AC coverage.** Every acceptance criterion number appears in the `AC` column of the test table.
3. **Signatures (soft).** For each `modify` step, the identifier of the signature (the name before `(`, or the type name) occurs in that file. A renamed identifier is legitimate, so this only produces a warning.

On a miss in 1 or 2, run the planner once more (`mode: plan`) with the misses stated. Misses that remain, and all warnings from 3, are shown at Checkpoint 1 under risks. After an amendment, run the gate again on the amended steps only (for these, check only that `modify`/`delete` paths exist, since earlier steps may have created the `new` ones).

## Checkpoint 1 — Plan approval

Show the user a compact summary built from `plan.md`, **not** the whole file:
- title and type
- goal
- acceptance criteria
- a table of steps, each with its file and a one-line change description
- the number of test cases, and which acceptance criteria each covers (flag any criterion with no test case)
- risks and open questions, plus any plan gate misses or warnings
- the **verify command** and the **lint command** (or `-`)
- the full path `.software-factory/runs/<id>/plan.md`

Then ask with AskUserQuestion:
- **Approve:** continue to implementation with this verify command.
- **Revise plan:** the user says what to change (via "Other" or a follow-up). Re-run `software-factory-planner` in `mode: plan` with the feedback appended to the prompt. User-requested revisions do not count against `amendments`. Return to Checkpoint 1.
- **Change verify command:** take the new verify and/or lint command, update `state.md`, and ask again.
- **Abort:** set `phase: aborted`, show the usage report and stop. Leave the run dir in place.

On approval:
1. Create the branch named in the `## Git` section of `plan.md`: `git switch -c <branch> <base_branch>`. Record `branch` in `state.md`.
2. **Baseline verify** (skip if `verify_cmd` is `none`; record `baseline: not run`). Run `verify_cmd` (without lint) as in Phase 4, but write `baseline.log` and leave the failure counters alone. If it fails, show the tail and ask: **Continue** (record `baseline: red`) / **Abort**. Otherwise record `baseline: green`. When the baseline is red, a Phase 4 failure whose error lines also appear in `baseline.log` is pre-existing: do not count it, and list it at checkpoint 2.
3. Set `phase: implement`.

## Phase 3 — Implement

Spawn `software-factory-implementer` with task `implement` (or `resume` after an amendment) and `RUN_DIR`. Validate `impl-report.md` (see Output validation), then branch on its `Status`:

- **`DONE` / `FIX_DONE`** → run the gates (next section), then set `phase: verify`.
- **`DEVIATION`:**
  - If `amendments` (from disk) = 2, or the repeat rule applies, stop at a **deviation checkpoint**. Show the deviation, the number of deviation rounds so far (`deviation` rows in `usage.md`) and ask: **Re-plan from scratch** (move all `plan-amendment-*.md` to `.software-factory/runs/<id>/superseded/`, then back to Phase 2 with the deviation as feedback; reset `amendments` and `verify_failures` to 0) / **Give instructions** (planner `mode: revise` with the user's text, then implementer `resume`) / **Abort**.
  - Otherwise:
    1. Count `amendments` from disk (see Loop caps) and write `state.md`.
    2. Spawn `software-factory-planner` with `mode: amend`, `N` (see Loop caps), and `RUN_DIR`. It reads all listed deviations from `impl-report.md`.
    3. If the amendment says `Scope change: yes`, show the amendment to the user and ask **Approve amendment / Revise / Abort** before continuing.
    4. Spawn `software-factory-implementer` with task `resume`.

## Gates (cheap deterministic checks, before verify)

Run these yourself with git and Grep; they cost no subagent tokens. Skip the test gates for steps that have no test cases.

1. **Scope.** Every path in `git --no-pager status --porcelain -uall` (leaving out `preexisting_dirty`) must be a path named in `plan.md` steps or amendments, or a test file named in the test cases. Anything else is out of scope.
2. **Tests present.** For every `file :: name` in the plan's test table (and amendments), Grep the file for the test name. A missing file or name is a miss.
3. **No weakened tests.** `git --no-pager diff <base_branch> -- <test files>` must not remove test annotations/functions or assertions that the plan did not replace, and must not add skip markers (`@Disabled`, `@Ignore`, `.skip(`, `xit(`, `xdescribe(`, `@pytest.mark.skip`, `t.Skip(`).

On a miss, count it like the 1st verify failure: increment `verify_failures` and spawn `software-factory-implementer` with task `fix` and the gate findings as the notes (for scope: revert the extra change or justify it under Adaptations). If a gate misses again after that, stop as for the 3rd verify failure. Record `gates: pass | fail` in `state.md`.

## Phase 4 — Verify (you run it, never trust the implementer's self-check)

If `verify_cmd` is `none` and `lint_cmd` is `-`, record `verify: not run (no build/test setup)` and go to Phase 4.5.

Otherwise run the command with the Bash tool, with `timeout` set to 600000. The command is `( <verify_cmd> ) && ( <lint_cmd> )`; leave out the part that is `none` or `-`. Use this form, so that only a short tail enters the context:

```bash
start=$(date +%s); ( ( <verify_cmd> ) && ( <lint_cmd> ) ) > .software-factory/runs/<id>/verify.log 2>&1; rc=$?; echo "exit=$rc duration=$(( $(date +%s) - start ))s"; [ $rc -eq 0 ] || tail -n 80 .software-factory/runs/<id>/verify.log
```

A lint failure is a normal verify failure.

A tool timeout (no `exit=` line printed) counts as a failure; record `last_verify: timeout`.

- **Pass** → record the duration and set `phase: review` (Phase 4.5). If the duration is over 180 s, note it, so that checkpoint 2 can suggest a narrower command for next time.
- **Fail** → increment `verify_failures`, then:
  - 1st failure → spawn `software-factory-implementer` with task `fix`, `RUN_DIR`, and the path `.software-factory/runs/<id>/verify.log`. Then go back to Phase 3's status handling, so that a DEVIATION during the fix is handled as a deviation.
  - 2nd failure → if `amendments` (from disk) < 2:
    1. Count `amendments` from disk and write `state.md`.
    2. Spawn `software-factory-planner` with `mode: diagnose`, `N` (see Loop caps), and `RUN_DIR` (it reads `verify.log`).
    3. Then spawn `software-factory-implementer` with task `resume`, and verify again.

    If `amendments` is already 2, stop as for the 3rd failure.
  - 3rd failure → stop at a checkpoint. Show the tail and the log path, and ask: **Give instructions** (planner `mode: revise` with the user's text, then implementer `resume`, then verify again; reset `verify_failures` to 0) / **Accept unverified and go to checkpoint 2** / **Abort**.

## Phase 4.5 — Review (a second opinion on the diff, before you see it)

The reviewer runs once per run. Skip this phase when `review:` in `state.md` is not `not run` (a review fix, or a change requested at checkpoint 2, is verified but not reviewed again), and go to checkpoint 2.

1. Set `phase: review`. Build the diff without reading it. Tracked changes first, leaving out `preexisting_dirty` paths with `:(exclude)<path>` pathspecs:
   `git --no-pager diff <base_branch> -- . > .software-factory/runs/<id>/review.diff`
   Then append every untracked file listed in `git --no-pager status --porcelain -uall` (the `??` lines, again without `preexisting_dirty`), one command per file:
   `git --no-pager diff --no-index /dev/null <file> >> .software-factory/runs/<id>/review.diff` (exit code 1 only means "differs").
2. Spawn `software-factory-reviewer` with `RUN_DIR`. Validate `review.md` (see Output validation) and record `review:` in `state.md`.
3. Branch on `Verdict`:
   - **`APPROVE`** → set `phase: checkpoint-2`.
   - **`CHANGES`** → increment `review_rounds`, spawn (or continue, see Token rules) `software-factory-implementer` with task `fix` and the path `.software-factory/runs/<id>/review.md`. Then run the gates, then Phase 4 (verify) with the normal `verify_failures` rules; a DEVIATION is handled as in Phase 3. Phase 4 then goes straight to checkpoint 2 (no second review). Findings that remain unfixed (a DEVIATION the user waved through, or the cap) are listed at checkpoint 2.

## Checkpoint 2 — Change approval

Show:
1. `git --no-pager status --porcelain -uall` (leaving out `preexisting_dirty` paths) and `git --no-pager diff --stat`.
2. The gate result (`gates:`) and the verify result: pass with duration, `not run (none)`, or `accepted unverified`. Also list pre-existing baseline failures, if any. If `full_cmd` differs from `verify_cmd`, say that only the narrow command ran and that the full command will run before a push.
3. The review result: verdict, how many blocker/major findings were fixed, and the open ones (rows, plus a one-line count of minors and the `review.md` path).
4. The **Adaptations** from `impl-report.md`, and any amendments with their one-line causes.
5. A draft commit message: the subject from the plan's `## Git` section (≤72 chars, ticket key included if there is one); the body gives what and why in 2-4 lines.
6. The subagent token total so far (one line, from `subagent_tokens`).
7. A hint that the user can inspect the full diff with `git diff` before deciding.

Ask with AskUserQuestion:
- **Commit, push and open PR**
- **Commit only (local):** no push.
- **Request changes:** the user describes them.
  - Small and within the plan → spawn `software-factory-implementer` with task `fix` and the user's notes.
  - Otherwise → spawn `software-factory-planner` with `mode: revise`, `N` (see Loop caps) and the notes, then the implementer with task `resume`. User-requested changes do not count against `amendments`.
  - Reset `verify_failures` to 0, verify again, and return here.
- **Abort:** leave the changes in the worktree on the branch, set `phase: aborted`, show the usage report, and stop.

## Phase 5 — Commit / PR

0. **Full suite before push.** If the user chose to push, `full_cmd` is not `-`, and it differs from `verify_cmd`, run it like Phase 4 (into `full.log`, same tail-only form, `timeout` 600000) and record `last_full:`. On failure or timeout show the tail and ask: **Fix** (implementer `fix` with the `full.log` path, then gates, verify and checkpoint 2 again) / **Push anyway** / **Commit only**.
1. Set `phase: commit`. Stage exactly the paths shown at checkpoint 2 (never `preexisting_dirty` paths), by explicit file path (`git add <paths>`, never `-A` or a directory), then commit with the approved message.
2. Push and PR (only if chosen): run `git push -u origin <branch>`. Then open the PR against `base_branch` with the first available option:
   1. a skill or MCP tool in this session that creates pull requests for this host (e.g. a bitbucket or github skill or MCP);
   2. `gh pr create` if the remote is GitHub and `gh` is installed, or `glab mr create` if the remote is GitLab and `glab` is installed;
   3. otherwise print the host's compare/new-PR URL for the branch.

   The PR title is the commit subject. The PR body gives the goal, the acceptance criteria as a checklist, the test cases added, the verify result, one line `Reviewed: <verdict>, <n> findings fixed`, and the ticket key or link.
3. Set `phase: done`, report the branch, commit SHA and PR URL in 3-5 lines, then show the usage report.

## `state.md` format (overwrite on every phase change and after every subagent return)

```markdown
# Factory run <id>
- input: <ticket key or first line of task>
- phase: explore | plan | checkpoint-1 | implement | verify | review | checkpoint-2 | commit | done | aborted
- base_branch: <name or ->
- branch: <name or ->
- verify_cmd: `<command>` | none
- lint_cmd: `<command>` | -
- full_cmd: `<command>` | -
- baseline: green | red | not run
- preexisting_dirty: <paths or ->
- amendments: <0-2>
- verify_failures: <n>
- review_rounds: <0-1>
- gates: <pass | fail | not run>
- last_verify: <pass 42s | fail | timeout | not run>
- last_full: <pass | fail | timeout | not run>
- review: <approve | changes (<b> blocker, <m> major) | not run>
- subagent_tokens: <running sum from usage.md>
- updated: <ISO timestamp>
- note: <one line: what happens next>
```
