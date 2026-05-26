---
mode: 'agent'
description: 'Review a pull request or merge request using pure git (no gh CLI). Provide the PR/MR number; the skill fetches the remote ref and compares it against the current branch or a specified base.'
tools: ['codebase', 'terminal']
---

# Review PR

Review a pull request or merge request using only git — no `gh` CLI or GitHub API required. Works with GitHub, GitLab, Gitea, Forgejo, Bitbucket, and any git remote that exposes PR refs.

## Arguments

- First argument: `PR_NUMBER` (required, integer)
- Second argument: `BASE` (optional branch name; defaults to current branch)

## Workflow

### 1. Fetch the PR Branch

Try in order, stopping at first success:

```bash
# GitHub / Gitea / Forgejo
git fetch origin "refs/pull/${PR_NUMBER}/head:pr/${PR_NUMBER}-review"

# GitLab / Bitbucket
git fetch origin "refs/merge-requests/${PR_NUMBER}/head:mr/${PR_NUMBER}-review"
```

If both fail, report the error and ask the user to provide the branch name directly.

### 2. Resolve the Base

Use the second argument if provided. Otherwise use the current branch (`git rev-parse --abbrev-ref HEAD`). If already on the remote default, auto-detect it: `git remote show origin 2>/dev/null | grep 'HEAD branch' | awk '{print $NF}'`.

### 3. Find the Merge Base

```bash
MERGE_BASE=$(git merge-base "$BASE" "$PR_BRANCH")
```

Use `$MERGE_BASE..$PR_BRANCH` for all diffs.

### 4. Gather Context

Run all three commands:

```bash
git log --oneline "$MERGE_BASE".."$PR_BRANCH"
git diff --stat "$MERGE_BASE".."$PR_BRANCH"
git diff "$MERGE_BASE".."$PR_BRANCH"
```

If `git log` produces no output, stop and inform the user that the PR branch has no commits ahead of the base.

Use `codebase` to read non-deleted, non-binary changed files. Limit individual file reads to files under 500 lines; for larger files, read only regions surrounding changed hunks.

### 5. Write the Review

**Summary** — what the PR does, commit count, files changed, scope assessment.

**Commits** — each commit with a one-line coherence note.

**Per-File Analysis** — for each changed file:
- What changed (neutral description)
- Concerns: correctness bugs, security issues, missing error handling, broken tests — omit if none
- Suggestions: non-blocking style/naming improvements — omit if none

Order files by severity. Group files with no issues under a single "No issues" list.

**Overall Assessment** — one of: Looks good / Needs minor changes / Needs major changes. Include cross-cutting concerns (missing tests, inconsistent patterns, performance implications).

## Edge Cases

- Fetch failure: ask user for branch name directly
- Deleted or binary files: note by name, skip content analysis
- Renamed files: focus on content changes within the rename
- Large diffs (500+ files): summarize at directory level
- No remote / offline: Step 1 will fail; ask user for branch name
