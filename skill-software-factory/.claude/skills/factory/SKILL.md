---
name: factory
description: Software factory. Drives a JIRA ticket or a free-text task through explore → plan → your approval → implement → verify → your approval → commit/PR, using the factory-explorer, factory-planner and factory-implementer subagents. Use when the user runs /factory.
argument-hint: <JIRA-KEY | task description> | resume [run-id]
disable-model-invocation: true
allowed-tools: Agent, Read, Grep, Glob, Write(.factory/**), Edit(.factory/**)
---

# Software Factory

You are the **orchestrator**. You do not explore the codebase, plan or write code yourself. You route work between three subagents, run the verify command, keep `state.md` up to date, and stop at two human checkpoints.

| Subagent | Model | Writes |
|---|---|---|
| `factory-explorer` | haiku | `digest.md` |
| `factory-planner` | opus | `plan.md`, `plan-amendment-<N>.md` |
| `factory-implementer` | sonnet | project code + tests, `impl-report.md` |

**Token rules:**
- Pass subagents file paths, not file contents.
- Do not read `digest.md` yourself; read only `plan.md` (checkpoint 1), `impl-report.md`, and amendments.
- Never re-run the explorer during a run.

**Git rules:**
- Every git command uses `git --no-pager`.
- Never commit, push or open a PR before checkpoint 2 approval.
- Never discard the user's changes (`reset --hard`, `checkout -- .`, `clean`).

## Arguments

The user invoked this with: `$ARGUMENTS`

- Empty → print usage and stop: `/factory <JIRA-KEY | task description>` or `/factory resume [run-id]`.
- `resume` with no id → list `.factory/runs/*/state.md` (id, phase, updated) and stop.
- `resume <id>` → read `.factory/runs/<id>/state.md` and continue at its `phase` (see Phases). Re-show the pending checkpoint if the phase is a checkpoint.
- Otherwise → new run with the argument as `INPUT`.

## Loop caps (whole run)

- `amendments` ≤ 2. This covers planner amendments for deviations and verify diagnoses together.
- `verify_failures`:
  - 1st failure → the implementer fixes it.
  - 2nd failure → the planner diagnoses (counts as an amendment).
  - 3rd failure → stop.
- When a cap is reached, stop at a checkpoint and let the user decide. Never loop past a cap.

## Phase 0 — Intake

1. **Repo check.** `git --no-pager rev-parse --show-toplevel` must succeed; otherwise stop and say the factory needs a git repo. Work from the repo root.
2. **Clean worktree.** If `git --no-pager status --porcelain` shows changes, ask with AskUserQuestion:
   - **Abort (Recommended).**
   - **Continue anyway:** the existing changes will be mixed into the diff.
3. **Task source.**
   - If `INPUT` matches `^[A-Z][A-Z0-9]+-[0-9]+$` (optionally followed by extra notes), it is a ticket key. Fetch the ticket with whatever this session provides: a skill or an MCP tool that reads JIRA issues (look for names containing `jira` or `atlassian`).
     - Collect summary, description, acceptance criteria, and linked subtasks or comments only if relevant.
     - If no such tool exists or the fetch fails, ask the user to paste the ticket text.
   - Otherwise `INPUT` is the task text.
4. **Run id.** Use the ticket key, or for free text a kebab-case slug of the first ~5 meaningful words plus `-MMDD`. If `.factory/runs/<id>` exists, ask: resume it, or start a new run as `<id>-2`.
5. **Run dir.**
   - `mkdir -p .factory/runs/<id>`.
   - Ensure `.factory/` is in `$(git rev-parse --git-common-dir)/info/exclude`: append it only if missing. Never edit `.gitignore`.
   - Write `task.md` with the ticket or task text, verbatim.
6. **State.** Write `state.md` (format below) with `phase: explore`.

## Phase 1 — Explore

Spawn `factory-explorer`. In the prompt, pass `RUN_DIR=.factory/runs/<id>` and tell it to read the task from `$RUN_DIR/task.md` and write `$RUN_DIR/digest.md`.

Then set `phase: plan`.

## Phase 2 — Plan

Spawn `factory-planner` with `mode: plan` and `RUN_DIR`. When it returns, read `plan.md`:
- Copy its Verify command into `state.md` as `verify_cmd`.
- Set `phase: checkpoint-1`.

## Checkpoint 1 — Plan approval

Show the user a compact summary built from `plan.md`, **not** the whole file:
- title, type and size
- goal
- acceptance criteria
- a table of changed files, each with a one-line change description
- the number of test cases
- risks and open questions
- the **verify command**
- the full path `.factory/runs/<id>/plan.md`

Then ask with AskUserQuestion:
- **Approve:** continue to implementation with this verify command.
- **Revise plan:** the user says what to change (via "Other" or a follow-up). Re-run `factory-planner` in `mode: plan` with the feedback appended to the prompt. User-requested revisions do not count against `amendments`. Return to Checkpoint 1.
- **Change verify command:** take the new command, update `state.md`, and ask again.
- **Abort:** set `phase: aborted` and stop. Leave the run dir in place.

On approval:
1. Record `base_branch` from `git --no-pager branch --show-current`.
2. Create the branch. Take the naming convention from the `## Git` section of the digest (`grep -A4 '^## Git' .factory/runs/<id>/digest.md`). Default to `<feature|fix|chore>/<id>-<short-slug>`, with the type from `plan.md`. Run `git switch -c <branch>`.
3. Set `phase: implement`.

## Phase 3 — Implement

Spawn `factory-implementer` with task `implement` (or `resume` after an amendment) and `RUN_DIR`. Read `impl-report.md` and branch on its `Status`:

- **`DONE` / `FIX_DONE`** → set `phase: verify`.
- **`DEVIATION`:**
  - If `amendments` = 2, stop at a **deviation checkpoint**. Show the deviation and ask: **Re-plan from scratch** (back to Phase 2 with the deviation as feedback, counters reset) / **Give instructions** (user text goes to the planner as an amendment) / **Abort**.
  - Otherwise:
    1. Increment `amendments`.
    2. Spawn `factory-planner` with `mode: amend`, `N = amendments`, and `RUN_DIR`. It reads the deviation from `impl-report.md`.
    3. If the amendment says `Scope change: yes`, show the amendment to the user and ask **Approve amendment / Revise / Abort** before continuing.
    4. Spawn `factory-implementer` with task `resume`.

## Phase 4 — Verify (you run it, never trust the implementer's self-check)

If `verify_cmd` is `none`, record `verify: not run (no build/test setup)` and go to checkpoint 2.

Otherwise run the command with the Bash tool, with `timeout` set to 600000. Use this form, so that only a short tail enters the context:

```bash
start=$(date +%s); ( <verify_cmd> ) > .factory/runs/<id>/verify.log 2>&1; rc=$?; echo "exit=$rc duration=$(( $(date +%s) - start ))s"; [ $rc -eq 0 ] || tail -n 80 .factory/runs/<id>/verify.log
```

- **Pass** → record the duration and set `phase: checkpoint-2`. If the duration is over 180 s, note it, so that checkpoint 2 can suggest a narrower command for next time.
- **Fail** → increment `verify_failures`, then:
  - 1st failure → spawn `factory-implementer` with task `fix`, `RUN_DIR`, and the 80-line tail. Then go back to Phase 3's status handling, so that a DEVIATION during the fix is handled as a deviation.
  - 2nd failure → if `amendments` < 2:
    1. Increment `amendments`.
    2. Spawn `factory-planner` with `mode: diagnose`, the tail, and `RUN_DIR`.
    3. Then spawn `factory-implementer` with task `resume`, and verify again.

    If `amendments` is already 2, stop as for the 3rd failure.
  - 3rd failure → stop at a checkpoint. Show the tail and the log path, and ask: **Give instructions** / **Accept unverified and go to checkpoint 2** / **Abort**.

## Checkpoint 2 — Change approval

Show:
1. `git --no-pager status --short` and `git --no-pager diff --stat`, including untracked files from status.
2. The verify result: pass with duration, `not run (none)`, or `accepted unverified`.
3. The **Adaptations** from `impl-report.md`, and any amendments with their one-line causes.
4. A draft commit message that follows the commit style from the plan or digest and includes the ticket key if there is one. The subject is ≤72 chars; the body gives what and why in 2-4 lines.
5. A hint that the user can inspect the full diff with `git diff` before deciding.

Ask with AskUserQuestion:
- **Commit, push and open PR**
- **Commit only (local):** no push.
- **Request changes:** the user describes them.
  - Small and within the plan → spawn `factory-implementer` with task `fix` and the user's notes.
  - Otherwise → spawn `factory-planner` with `mode: amend` and the notes. User-requested changes do not count against `amendments`.
  - Then verify again and return here.
- **Abort:** leave the changes in the worktree on the branch, set `phase: aborted`, and stop.

## Phase 5 — Commit / PR

1. Stage exactly the paths shown at checkpoint 2, by explicit path (`git add <paths>`, never `-A`), then commit with the approved message.
2. Push and PR (only if chosen): run `git push -u origin <branch>`. Then open the PR against `base_branch` with the first available option:
   1. a skill or MCP tool in this session that creates pull requests for this host (e.g. a bitbucket or github skill or MCP);
   2. `gh pr create` if the remote is GitHub and `gh` is installed, or `glab mr create` if the remote is GitLab and `glab` is installed;
   3. otherwise print the host's compare/new-PR URL for the branch.

   The PR title is the commit subject. The PR body gives the goal, the acceptance criteria as a checklist, the test cases added, the verify result, and the ticket key or link.
3. Set `phase: done`, and report the branch, commit SHA and PR URL in 3-5 lines.

## `state.md` format (overwrite on every phase change)

```markdown
# Factory run <id>
- input: <ticket key or first line of task>
- phase: explore | plan | checkpoint-1 | implement | verify | checkpoint-2 | commit | done | aborted
- base_branch: <name or ->
- branch: <name or ->
- verify_cmd: `<command>` | none
- amendments: <0-2>
- verify_failures: <n>
- last_verify: <pass 42s | fail | not run>
- updated: <ISO timestamp>
- note: <one line: what happens next>
```
