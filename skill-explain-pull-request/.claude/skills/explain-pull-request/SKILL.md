---
name: explain-pull-request
description: Resolve a pull request or merge request number to git branches, then analyze the changes. Use when the user asks to "explain PR 123", "analyze pull request 45", "what does MR 7 do", or "explain this PR". Takes a PR/MR number and an optional base branch. Works with GitHub, Bitbucket Server, and GitLab — no gh CLI required.
argument-hint: <pr-number> [base-branch]
allowed-tools: [Bash, Skill]
---

# Explain Pull Request

Resolve a PR/MR number to git branches using only git, then invoke the `explain-diff` skill to analyze the changes.

**Important:** this skill only fetches temporary refs and reads git metadata. It never touches the working tree, the index, or the current branch — the user's local state is never affected.

**Rule:** every git command MUST use the `--no-pager` flag (`git --no-pager <command>`) to prevent interactive pager prompts.

## Arguments

The user invoked this with: `$ARGUMENTS`

Parse arguments:
- First token → `PR_NUMBER` (required, integer)
- Second token → `BASE_BRANCH` (optional; if provided, skip Step 2)

If `PR_NUMBER` is missing or not an integer, stop: `Usage: /explain-pull-request <pr-number> [base-branch]`

## Step 1 — Fetch the PR Branch

Try remote ref conventions in order, stopping at the first success. Always set `GIT_TERMINAL_PROMPT=0` to prevent interactive credential prompts:

```bash
# GitHub / Gitea / Forgejo
GIT_TERMINAL_PROMPT=0 git fetch origin "refs/pull/${PR_NUMBER}/head:pr/${PR_NUMBER}-explain" 2>&1

# Bitbucket Server / Data Center
GIT_TERMINAL_PROMPT=0 git fetch origin "refs/pull-requests/${PR_NUMBER}/from:pr/${PR_NUMBER}-explain" 2>&1

# GitLab
GIT_TERMINAL_PROMPT=0 git fetch origin "refs/merge-requests/${PR_NUMBER}/head:mr/${PR_NUMBER}-explain" 2>&1
```

Record the local branch name (`pr/<N>-explain` or `mr/<N>-explain`) as `PR_BRANCH`.

If all three fetches fail, report the error clearly and ask the user to provide the branch name directly and run `/explain-diff <feature-branch> <base-branch>` instead. Stop.

## Step 2 — Resolve Base Branch

Never use the current local branch — it belongs to the user's work, not the PR.

Try each strategy in order, stopping at the first success:

**a) Bitbucket Server target ref:**
```bash
GIT_TERMINAL_PROMPT=0 git fetch origin "refs/pull-requests/${PR_NUMBER}/to:pr/${PR_NUMBER}-base" 2>&1
```
If this succeeds, use `pr/${PR_NUMBER}-base` as `BASE_BRANCH`.

**b) Scan commit ancestry for the first remote tracking ref:**
```bash
git --no-pager log --format='%D' "${PR_BRANCH}^" 2>/dev/null \
  | tr ',' '\n' \
  | sed 's/^ *//' \
  | grep -E '^origin/.' \
  | grep -v '/HEAD$' \
  | head -1
```
This walks the *ancestor* commits of the PR branch (starting from the parent of the tip, so the tip's own `origin/<source-branch>` decoration is not considered) and returns the first `origin/<name>` decoration encountered — the branch the PR was most likely based on. The `2>/dev/null` handles the rare case of an orphan tip with no parent. If the result is empty, fall through to the next strategy. Use a non-empty result as `BASE_BRANCH`.

**c) Remote default branch:**
```bash
git --no-pager remote show -n origin 2>/dev/null | grep 'HEAD branch' | awk '{print $NF}'
```
Use `-n` (no network access) to avoid credential prompts. Prefix the result with `origin/` to get the full remote ref. Use as `BASE_BRANCH`.

**d) Last resort:** use `origin/main`, or `origin/master` if `origin/main` does not exist.

## Step 3 — Invoke explain-diff

**After resolving `PR_BRANCH` and `BASE_BRANCH`, you MUST immediately call the `explain-diff` skill using the Skill tool. Do not summarize the resolved branches and stop — the analysis is performed by explain-diff, not here.**

Call the Skill tool with:
- `skill`: `explain-diff`
- `args`: `<PR_BRANCH> <BASE_BRANCH>`

If all fetches failed and you have no `PR_BRANCH`, stop with an error as described in Step 1.
