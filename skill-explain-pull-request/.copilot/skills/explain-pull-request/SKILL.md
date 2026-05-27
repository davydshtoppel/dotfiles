---
mode: 'agent'
description: 'Resolve a pull request or merge request number to git branches, then invoke explain-diff to analyze the changes. Works with GitHub, Bitbucket Server, and GitLab — no gh CLI required. Never touches the working tree or current branch.'
tools: ['terminal']
---

# Explain Pull Request

Resolve a PR/MR number to git branches using only git, then invoke the `explain-diff` skill to analyze the changes.

**Important:** this skill only fetches temporary refs and reads git metadata. It never touches the working tree, the index, or the current branch — the user's local state is never affected.

## Arguments

- First argument: `PR_NUMBER` (required, integer)
- Second argument: `BASE_BRANCH` (optional; if provided, skip Step 2)

If `PR_NUMBER` is missing or not an integer, stop: `Usage: /explain-pull-request <pr-number> [base-branch]`

## Workflow

### 1. Fetch the PR Branch

Try in order, stopping at first success:

```bash
# GitHub / Gitea / Forgejo
git fetch origin "refs/pull/${PR_NUMBER}/head:pr/${PR_NUMBER}-explain"

# Bitbucket Server / Data Center
git fetch origin "refs/pull-requests/${PR_NUMBER}/from:pr/${PR_NUMBER}-explain"

# GitLab
git fetch origin "refs/merge-requests/${PR_NUMBER}/head:mr/${PR_NUMBER}-explain"
```

Record the local branch name as `PR_BRANCH`. If all three fail, report the error and ask the user to provide branch names and run `/explain-diff` directly.

### 2. Resolve Base Branch

Never use the current local branch — it belongs to the user's work, not the PR.

Try each strategy in order, stopping at the first success:

**a) Bitbucket Server target ref:**
```bash
git fetch origin "refs/pull-requests/${PR_NUMBER}/to:pr/${PR_NUMBER}-base"
```
If this succeeds, use `pr/${PR_NUMBER}-base`.

**b) Find closest remote branch by ancestry:**
```bash
git --no-pager fetch origin
git --no-pager for-each-ref --format='%(refname:short)' refs/remotes/origin \
  | grep -v 'HEAD' \
  | while read ref; do
      count=$(git --no-pager rev-list "${ref}..${PR_BRANCH}" --count 2>/dev/null)
      echo "$count $ref"
    done \
  | sort -n \
  | head -1 \
  | awk '{print $2}'
```
Use the result (the remote branch with fewest commits ahead of the PR's divergence point).

**c) Remote default branch:**
```bash
git --no-pager remote show origin 2>/dev/null | grep 'HEAD branch' | awk '{print $NF}'
```
Prefix with `origin/` and use as `BASE_BRANCH`.

**d) Last resort:** `origin/main`, or `origin/master` if `origin/main` does not exist.

### 3. Invoke explain-diff

Invoke the `explain-diff` skill with the resolved branches:

```
/explain-diff <PR_BRANCH> <BASE_BRANCH>
```
