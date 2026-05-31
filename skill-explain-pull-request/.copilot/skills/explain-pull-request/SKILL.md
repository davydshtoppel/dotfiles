---
mode: 'agent'
description: 'Resolve a pull request or merge request number to git branches, then invoke explain-diff to analyze the changes. Works with GitHub, Bitbucket Server, and GitLab — no gh CLI required. Never touches the working tree or current branch.'
tools: ['terminal']
---

# Explain Pull Request

Resolve a PR/MR number to git branches using only git, then invoke the `explain-diff` skill to analyze the changes.

**Important:** this skill only fetches temporary refs and reads git metadata. It never touches the working tree, the index, or the current branch — the user's local state is never affected.

**Rule:** every git command MUST use the `--no-pager` flag (`git --no-pager <command>`) to prevent interactive pager prompts.

## Arguments

- First argument: `PR_NUMBER` (required, integer)
- Second argument: `BASE_BRANCH` (optional; if provided, skip Step 2)

If `PR_NUMBER` is missing or not an integer, stop: `Usage: /explain-pull-request <pr-number> [base-branch]`

## Workflow

### 1. Fetch the PR Branch

Try in order, stopping at first success. Always set `GIT_TERMINAL_PROMPT=0` to prevent interactive credential prompts:

```bash
# GitHub / Gitea / Forgejo
GIT_TERMINAL_PROMPT=0 git fetch origin "refs/pull/${PR_NUMBER}/head:pr/${PR_NUMBER}-explain" 2>&1

# Bitbucket Server / Data Center
GIT_TERMINAL_PROMPT=0 git fetch origin "refs/pull-requests/${PR_NUMBER}/from:pr/${PR_NUMBER}-explain" 2>&1

# GitLab
GIT_TERMINAL_PROMPT=0 git fetch origin "refs/merge-requests/${PR_NUMBER}/head:mr/${PR_NUMBER}-explain" 2>&1
```

Record the local branch name as `PR_BRANCH`. If all three fail, report the error and ask the user to provide branch names and run `/explain-diff` directly.

### 2. Resolve Base Branch

Never use the current local branch — it belongs to the user's work, not the PR.

Try each strategy in order, stopping at the first success:

**a) Bitbucket Server target ref:**
```bash
GIT_TERMINAL_PROMPT=0 git fetch origin "refs/pull-requests/${PR_NUMBER}/to:pr/${PR_NUMBER}-base" 2>&1
```
If this succeeds, use `pr/${PR_NUMBER}-base`.

**b) Scan commit ancestry for the first remote tracking ref:**
```bash
git --no-pager log --format='%D' "${PR_BRANCH}^" 2>/dev/null \
  | tr ',' '\n' \
  | sed 's/^ *//' \
  | grep -E '^origin/.' \
  | grep -v '/HEAD$' \
  | head -1
```
Walks the *ancestor* commits of the PR branch (starting from the parent of the tip, so the tip's own `origin/<source-branch>` decoration is not considered) and returns the first `origin/<name>` decoration encountered. The `2>/dev/null` handles the rare case of an orphan tip with no parent. If the result is empty, fall through to the next strategy.

**c) Remote default branch:**
```bash
git --no-pager remote show -n origin 2>/dev/null | grep 'HEAD branch' | awk '{print $NF}'
```
Use `-n` (no network access) to avoid credential prompts. Prefix with `origin/` and use as `BASE_BRANCH`.

**d) Last resort:** `origin/main`, or `origin/master` if `origin/main` does not exist.

### 3. Invoke explain-diff

**Immediately invoke the `explain-diff` skill with the resolved branches. Do not stop here.**

```
/explain-diff <PR_BRANCH> <BASE_BRANCH>
```
