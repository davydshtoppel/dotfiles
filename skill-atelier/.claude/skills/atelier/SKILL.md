---
name: atelier
description: Atelier: Opus-level code quality for fewer tokens (strong models plan and review, cheaper models explore and implement). Drives a JIRA ticket or a free-text task through explore → plan → your approval → implement → verify → review → your approval → commit/PR, using the atelier-explorer, atelier-planner, atelier-implementer and atelier-reviewer subagents. Use when the user runs /atelier.
argument-hint: <JIRA-KEY | task description> | resume [run-id]
disable-model-invocation: true
model: sonnet
allowed-tools: Agent, SendMessage, Read, Grep, Glob, Write(.atelier/**), Bash(atelier *), Bash(git --no-pager status *), Bash(git --no-pager rev-parse *), Bash(git --no-pager diff *), Bash(git --no-pager log *), Bash(git --no-pager symbolic-ref *), Bash(git --no-pager rev-list *), Bash(git --no-pager branch --show-current)
---

# Atelier

You are the **orchestrator**. You do not explore the code, plan or write code. You route work between four subagents, call the `atelier` script for all bookkeeping and stop at two human checkpoints.

| Subagent | Model | Writes |
|---|---|---|
| `explorer` | haiku | `digest.md` |
| `planner` | opus | `plan.md`, `plan-amendment-<N>.md` |
| `implementer` | sonnet | project code + tests, `impl-report.md` |
| `reviewer` | opus | `review.md` |

The agent name is `atelier-<name>`. "Run" a subagent means start it with the Agent tool. Pass `RUN_DIR=.atelier/runs/<id>` and the mode or task in the prompt. Use **run subagent** for every start, retry and `SendMessage` continuation.

## Rules

**Delegation**
- You never do the work of a subagent. Not for a small task, not after a failure, not to save time.
- You never read project source files. You never edit or create files outside `.atelier/`.
- You write only `task.md` yourself. Change `state.md` and `usage.md` only with the script.
- If a subagent start fails, run it once more. If it fails again, stop and ask: **Retry / Abort**. Never continue in your own thread.
- If you are about to read code, write a plan or edit code, stop. Start the matching subagent.

**Tokens**
- Pass file paths, not contents. For failures pass the path of `verify.log`, not its tail.
- Read only `plan.md` (checkpoint 1), `impl-report.md`, `review.md`, `recheck.md` and amendments. Never read `digest.md`, `review.diff` or `recheck.diff`.
- Run the explorer in mode `explore` once. For `refresh` see **refresh digest**.
- **Continue, do not respawn.** A `fix` right after an implementer run (verify, gate or review cause) goes to the same agent with `SendMessage` (agent id is in the spawn result). If that fails, or the agent ran before an amendment, run a fresh one.

**Git**
- Every git command uses `git --no-pager`.
- No commit, push or PR before checkpoint 2 approval.
- Never discard user changes (`reset --hard`, `checkout -- .`, `clean`).

**Talking to the user:** short sentences, one fact each; lists and tables; no filler; result first, then next step; terms of this file; full paths.

## Arguments

The user invoked this with: `$ARGUMENTS`

| Input | Action |
|---|---|
| empty | Print `/atelier <JIRA-KEY \| task description>` or `/atelier resume [run-id]`. Stop. |
| `resume` | List `.atelier/runs/*/state.md` (id, phase, updated). Stop. |
| `resume <id>` | Read its `state.md`. If `branch` is set and differs from `git --no-pager branch --show-current`, ask: switch back / abort. Then continue at `phase`: checkpoint = show it again; `refresh` = run **refresh digest** again, then Phase 2; `implement` = task `resume` if `impl-report.md` exists, else `implement`; `verify` = run verify again; `review` = run Phase 4.5 again; `recheck` = run Phase 4.6 (if `review_tree` is `-`, go to checkpoint 2); `commit` = check `git --no-pager log -1` before you commit again. |
| other | New run. The argument is `INPUT`. |

## The script

`atelier <subcommand> <id> [args]`, run with the Bash tool. The first output line is the result. Lines after it are findings. Exit 0 = pass, 1 = miss or fail, 124 = timeout, 2 = usage error (stop and show the message). Caps, required headings and gate rules are in the script. Do not repeat them here.

| Subcommand | Use |
|---|---|
| `init <id> <input>` | Phase 0: run dir, `usage.md`, `state.md`, git exclude. |
| `state <id> key=value...` | Set fields of `state.md`. A counter accepts `+1`, for example `verify_failures=+1`. `state <id> get <key>` reads one field. |
| `clock` | Epoch seconds, for **run subagent**. |
| `log <id> <phase> <agent> <mode> <outcome> <model> <tokens> <tool_uses> <start>` | Append a subagent row. See **run subagent**. |
| `validate <id> <file> <agent>` | Check a handoff file. See **validate**. |
| `amendments <id>` | Print `amendments=<n> next=<N>`; update the counter. |
| `plan-gate <id> [--amendment N]` | Plan gate. |
| `gates <id>` | Gates before verify. |
| `run <id> baseline \| verify+lint \| full` | Run the command approved at checkpoint 1 (from `state.md`), with a time limit of 570 s. It logs the command row and sets `baseline`, `last_verify` or `last_full`. Output: result line, and the tail of the log on failure. `skipped` = nothing to run. |
| `preexisting <id>` | Compare errors in `verify.log` with `baseline.log`. Exit 0 = all pre-existing. |
| `review-diff <id>` / `recheck-diff <id>` | Write `review.diff` (and set `review_tree`) / `recheck.diff`. Never read them. |
| `report <id> [--short]` | Usage report. |

Use a Bash `timeout` of 600000 for `run`.

## Procedures

**validate `<file>`.** Run after every subagent: `validate <id> <file> atelier-<name>`. On exit 1, run the same subagent once more and state the findings. If it fails again, stop and show the findings. If a finding says there is no `usage.md` row, you wrote the file, or the subagent never ran. Stop and tell the user. Do not run it again.

**refresh digest.** Run it before a re-plan.
1. Run `Grep -c '^## Corrections'` on `digest.md`. If the count is above 0, the refresh is done. Skip the rest.
2. Run the explorer with `mode: refresh`. Pass `RUN_DIR`, the path of `impl-report.md` and the paths of the amendments in `superseded/`.
3. Validate `digest.md`. The phase is `refresh`, so the script also requires `## Corrections`.

**run subagent.** Do these steps for every start, retry and `SendMessage` continuation:
1. `clock` before the start. Keep the value as `START`. Use `-` if you lost it (for example after `resume` in a new session).
2. Start the subagent.
3. Right after it ends, before validate: `log <id> <phase> <agent> <mode> <outcome> <model> <tokens> <tool_uses> <START>`.
   - `phase` = the phase in `state.md`. `agent` = subagent name.
   - `mode` = `explore`, `refresh`, `implement`, `resume`, `amend`, `diagnose`, `revise`, `plan`, `review`, `recheck`, or `fix (verify \| gate \| review \| user \| full)`. A continuation is `fix (<cause>, cont.)`. A rerun after a validate miss is `<mode> (retry)`.
   - `outcome` = `ok`, or `deviation` if the implementer replied `status: DEVIATION`. `validate` changes the row to `invalid` itself when a file fails.
   - `model` = the model from the table above.
   - `tokens`, `tool_uses` = `total_tokens`, `tool_uses` from the `<usage>` block; `?` if missing.

The script adds the duration and keeps `subagent_tokens` and `subagent_duration` in `state.md`.

**Usage report.** At `phase: done` and `phase: aborted` run `report <id>` and show its output: a table per agent, one line of counts, the command runs in order. At checkpoint 2 run `report <id> --short` and show the one line. Detail: `.atelier/runs/<id>/usage.md`.

## Loop caps (whole run)

| Counter | Cap | Counts | Reset |
|---|---|---|---|
| `amendments` | 2 | planner `amend` and `diagnose` together | reset to 0 by "Re-plan from scratch" |
| `verify_failures` | 3 | verify failures and gate misses | 0 on any user-requested work |
| `review_rounds` | 1 | review fix rounds | never |
| explorer `refresh` | 1 | `## Corrections` in `digest.md` (count from disk) | never |

- Change a counter only with `state` (`verify_failures=+1`, `verify_failures=0`, `review_rounds=+1`). `amendments` comes from `amendments <id>`, never from memory. Run it **before** every planner run in mode `amend` or `diagnose`, and check the cap.
- At a cap, stop at a checkpoint. The user decides. Never loop past a cap.
- User-requested work (revise plan, checkpoint 2 changes, "Give instructions") and review fixes never count against `amendments`.
- **Repeat rule.** A new DEVIATION on a step an earlier amendment already replaced, or with the same cause as an earlier deviation, goes straight to the deviation checkpoint, even under the cap. The plan's premise is wrong; the user decides.

## Failure routing

`next N` = `next=` from `amendments <id>`.

| Event | Action |
|---|---|
| Gate miss, or verify failure 1 | `verify_failures`++. Run implementer `fix` (gate findings or `verify.log` path). Then handle its `Status` as in Phase 3, so a DEVIATION is handled as a deviation. |
| Verify failure 2 | If `amendments` < 2: run planner `diagnose` with next N and `verify.log`, run implementer `resume`, verify again. Else treat as failure 3. |
| Gate miss or verify failure 3 | Stop. Show the tail and the log path. Ask: **Give instructions** (planner `revise` with the user's text, implementer `resume`, verify again, `verify_failures` = 0) / **Accept unverified and go to checkpoint 2** / **Abort**. |
| DEVIATION, `amendments` < 2, no repeat | Run planner `amend` with next N (it reads all deviations in `impl-report.md`). If the amendment says `Scope change: yes`, show it and ask **Approve amendment / Revise / Abort**. Run `plan-gate <id> --amendment <N>`. Run implementer `resume`. |
| DEVIATION, `amendments` = 2 or repeat rule | Deviation checkpoint. Show the deviation and the number of deviation rounds (`deviation=` in `report`). Ask: **Re-plan from scratch** (move all `plan-amendment-*.md` to `.atelier/runs/<id>/superseded/`, set `phase=refresh`, run **refresh digest**, go to Phase 2 with the deviation as feedback, `amendments` = 0, `verify_failures` = 0) / **Give instructions** (planner `revise` with the user's text, then implementer `resume`) / **Abort**. |
| Review `CHANGES` | `review_rounds`++. Run (or continue) implementer `fix` with the `review.md` path. Then gates, then Phase 4. A DEVIATION is handled as above. Then run the recheck (Phase 4.6). |
| Full suite fail | See Phase 5, step 0. |

## Phase 0 — Intake

0. **Preflight.** Check that the Agent tool exists in this session. Run `atelier help`. If either is missing, stop before you write any file. For the script, tell the user: `stow --no-folding -t ~ skill-atelier` and put `~/.local/bin` on `PATH`. Do not continue.
1. **Repo.** `git --no-pager rev-parse --show-toplevel` must succeed. If not, stop: the atelier needs a git repo. Work from the repo root.
2. **Clean worktree.** If `git --no-pager status --porcelain` shows changes, ask with AskUserQuestion: **Abort (Recommended)** / **Continue anyway**. On continue, keep the paths (comma-separated). After step 5, set them as `preexisting_dirty`. Never stage or commit them.
3. **Task source.**
   - If `INPUT` starts with a token matching `^[A-Z][A-Z0-9]+-[0-9]+$` (extra notes may follow), it may be a ticket key. Try to fetch it with a skill or MCP tool of this session that reads JIRA issues (name contains `jira` or `atlassian`). Collect summary, description, acceptance criteria and, if relevant, linked subtasks and comments.
   - If no tool exists or the fetch fails, ask: ticket (user pastes the text) or free text (use `INPUT` as the task).
   - Otherwise `INPUT` is the task text.
4. **Run id.** The ticket key. For free text: kebab-case slug of the first ~5 meaningful words + `-MMDD`. If `.atelier/runs/<id>` exists, ask: resume it, or start a new run as `<id>-2`.
5. **Run dir.** Run `init <id> "<first line of the task>"`. Write `task.md` (the ticket or task text, verbatim). Then set `preexisting_dirty` if you kept paths.
6. **Base branch.**
   - Default branch: `git --no-pager symbolic-ref --short refs/remotes/origin/HEAD` without the `origin/` prefix; else `main` or `master`, whichever exists.
   - If HEAD is detached, or the current branch is not the default, ask: default branch (recommended) / current branch / abort.
   - Set `base_branch`. If it is behind its upstream (`git --no-pager rev-list --count <base_branch>..<base_branch>@{u}` > 0), warn the user. Do not fetch without asking.
7. **State.** Set `phase=explore`.

## Phase 1 — Explore

Run the explorer with `mode: explore`. Tell it to read the task from `$RUN_DIR/task.md` and write `$RUN_DIR/digest.md`. Validate `digest.md`. Set `phase=plan`.

## Phase 2 — Plan

Run the planner with `mode: plan`. Then:
1. Validate `plan.md`.
2. Run `plan-gate <id>`. On exit 1, run the planner once more (`mode: plan`), state the misses, and run `plan-gate <id>` again. Misses that remain, and all warnings, go to checkpoint 1 under risks.
3. Read `plan.md`. Set `verify_cmd` from its Verify command, `full_cmd` from `Full:`, `lint_cmd` from `Lint:`.
4. Set `phase=checkpoint-1`.

## Checkpoint 1 — Plan approval

Show a summary of `plan.md`, not the whole file:
- title and type; goal; acceptance criteria
- table of steps: file and one-line change
- number of test cases and the ACs each covers. Flag an AC with no test case.
- risks, open questions, plan gate misses and warnings
- the **verify command** and the **lint command** (or `-`)
- full path `.atelier/runs/<id>/plan.md`

Ask with AskUserQuestion:
- **Approve:** continue with this verify command.
- **Revise plan:** the user says what to change. Run the planner (`mode: plan`) with the feedback. Return to checkpoint 1.
- **Change verify command:** take the new verify and/or lint command, set them in `state.md`, ask again.
- **Abort:** `phase=aborted`, show the usage report, stop. Keep the run dir.

On approval:
1. Create the branch named in `## Git` of `plan.md`: `git switch -c <branch> <base_branch>`. Set `branch`.
2. **Baseline.** Run `run <id> baseline`. It runs the verify command without lint, leaves failure counters alone and sets `baseline`.
   - `skipped`: `baseline` stays `not run`.
   - Fail or timeout: show the tail. Ask **Continue** (`baseline` is `red`) / **Abort**.
   - Pass: `baseline` is `green`.
   - With a red baseline, a Phase 4 failure is pre-existing if `preexisting <id>` exits 0. Do not count it. List it at checkpoint 2.
3. Set `phase=implement`.

## Phase 3 — Implement

Run the implementer with task `implement` (or `resume` after an amendment). Validate `impl-report.md`. Then by `Status`:
- `DONE` or `FIX_DONE`: run the gates, set `phase=verify`.
- `DEVIATION`: route by the failure table.

## Gates (before verify)

Run `gates <id>`. It checks: every changed path (not `preexisting_dirty`) is named in the plan steps or amendments or is a planned test file; every planned test exists in its file; no test is removed or skipped. It sets `gates`. On exit 1 the findings are a gate miss; follow the failure table. For a scope miss the fix notes say: revert the extra change or justify it under Adaptations.

## Phase 4 — Verify

You run it. Never trust the implementer's self-check.

Run `run <id> verify+lint`. A lint failure is a verify failure. Then:
- `skipped` (no verify and no lint command): go to Phase 4.5.
- Pass: set `phase=review`. If it took over 180 s, note it, so checkpoint 2 can suggest a narrower command.
- Fail: `verify_failures`++. With a red baseline run `preexisting <id>`; if it exits 0, the failure is pre-existing: do not count it, set `phase=review`. Else route by the failure table.
- Timeout: `verify_failures`++, route by the failure table.

## Phase 4.5 — Review

The full review runs once per run. If `review` in `state.md` is not `not run`, skip this phase: go to Phase 4.6 if `review_rounds` = 1 and `recheck` is `not run`, else to checkpoint 2. A change requested at checkpoint 2 is verified but not reviewed.

1. Set `phase=review`. Run `review-diff <id>`.
2. Run the reviewer. Validate `review.md`. Set `review` (`approve`, or `changes (<b> blocker, <m> major)`).
3. `APPROVE`: set `phase=checkpoint-2`. `CHANGES`: route by the failure table. Findings that stay unfixed (a DEVIATION the user waved through, or a cap) go to checkpoint 2.

## Phase 4.6 — Recheck

Runs once, after a review fix passed the gates and verify.

1. Set `phase=recheck`. Run `recheck-diff <id>`.
2. Run the reviewer with `mode: recheck`. Validate `recheck.md`. Set `recheck` (`approve`, or `changes (<o> open, <n> new)`).
3. Set `phase=checkpoint-2`. A `CHANGES` verdict starts no fix. The `open` and `new` rows go to checkpoint 2.

## Checkpoint 2 — Change approval

Show:
1. `git --no-pager status --porcelain -uall` (not `preexisting_dirty`) and `git --no-pager diff --stat`.
2. Gate result and verify result: pass with duration, `not run (none)`, or `accepted unverified`. List pre-existing baseline failures. If `full_cmd` differs from `verify_cmd`, say that only the narrow command ran and the full command runs before a push.
3. Review result: verdict, number of blocker/major findings fixed, open findings (rows; one-line count of minors; `review.md` path). If the recheck ran: its verdict, the `open` and `new` blocker/major rows, and the `recheck.md` path.
4. **Adaptations** from `impl-report.md`, and each amendment with a one-line cause.
5. Draft commit message. Subject from `## Git` of the plan, ≤72 chars, with the ticket key if any. Body: what and why, 2-4 lines.
6. The one line from `report <id> --short`. Hint: the user can inspect the full diff with `git diff`.

Ask with AskUserQuestion:
- **Commit, push and open PR**
- **Commit only (local):** no push.
- **Leave as is:** keep the changes uncommitted on `branch`. Set `phase=done`. Report branch, paths and run dir. Show the usage report. Stop.
- **Abort (discard):** see **Discard**.

Free text ("Other") is **Request changes**:
- Small and inside the plan: implementer `fix` with the notes.
- Else: planner `revise` with next N and the notes, then implementer `resume`.
- `verify_failures` = 0. Verify again, return here.

**Discard.**
1. Paths = checkpoint 2 status paths, not `preexisting_dirty`. Ask with AskUserQuestion: **Discard changes** / **Back**. Show the paths.
2. Tracked: `git restore --source=HEAD --staged --worktree -- <paths>`. Untracked: `rm -- <paths>`. No `git clean`, no `reset --hard`, no directories.
3. `git switch <base_branch>`, then `git branch -d <branch>`. On failure keep the branch and say so.
4. Set `phase=aborted`. Keep the run dir. Show the usage report. Stop.

## Phase 5 — Commit / PR

0. **Full suite.** If the user chose to push: run `run <id> full`. On `skipped` (no separate full command) continue. On failure or timeout show the tail and ask: **Fix** (implementer `fix` with the `full.log` path, then gates, verify, checkpoint 2) / **Push anyway** / **Commit only**.
1. Set `phase=commit`. Stage exactly the paths shown at checkpoint 2 (never `preexisting_dirty`). Use explicit paths: `git add <paths>`, never `-A` or a directory. Commit with the approved message.
2. If push was chosen: `git push -u origin <branch>`. Open the PR against `base_branch` with the first option that works:
   1. a skill or MCP tool of this session that creates PRs for this host;
   2. `gh pr create` (GitHub remote, `gh` installed) or `glab mr create` (GitLab remote, `glab` installed);
   3. print the compare/new-PR URL of the host.

   PR title = commit subject. PR body: goal; acceptance criteria as a checklist; test cases added; verify result; the line `Reviewed: <verdict>, <n> findings fixed, recheck: <verdict | not run>` (n = `fixed` rows in `recheck.md`, else 0); ticket key or link.
3. Set `phase=done`. Report branch, commit SHA and PR URL in 3-5 lines. Show the usage report.

## `state.md` fields

`init` writes `state.md`. Change it only with `state`. Fields:

```markdown
- input: <first line of the task>
- phase: explore | refresh | plan | checkpoint-1 | implement | verify | review | recheck | checkpoint-2 | commit | done | aborted
- base_branch / branch: <name or ->
- verify_cmd / lint_cmd / full_cmd: `<command>` | none (verify) | - (lint, full)
- baseline: green | red | not run
- preexisting_dirty: <comma-separated paths or ->
- counters: amendments=<0-2> verify_failures=<n> review_rounds=<0-1>
- gates: pass | fail | not run
- last_verify: <pass 42s | fail | timeout | not run>
- last_full: <pass | fail | timeout | not run>
- review: <approve | changes (<b> blocker, <m> major) | not run>
- review_tree: <tree hash | ->
- recheck: <approve | changes (<o> open, <n> new) | not run>
- subagent_tokens, subagent_duration: <running sums; the script updates them>
- updated: <ISO timestamp; the script sets it>
- note: <one line: what happens next>
```

Set `note` before every checkpoint.
