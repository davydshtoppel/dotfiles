---
name: review-pr
description: Review a pull request or merge request using pure git. Use when the user asks to "review PR 123", "review MR 45", "check pull request 7", or "review this PR". Takes a PR/MR number and fetches the remote ref to compare against the current branch (or a specified base branch).
argument-hint: <pr-number> [base-branch]
allowed-tools: [Bash, Read, Glob, Grep]
---

# Review PR

Perform a thorough code review of a pull request or merge request using only git — no `gh` CLI or GitHub API required. Works with GitHub, GitLab, Gitea, Forgejo, Bitbucket, and any git remote that exposes PR refs.

## Arguments

The user invoked this with: `$ARGUMENTS`

Parse arguments:
- First token → `PR_NUMBER` (required, integer)
- Second token → `BASE` (optional branch name; see Step 2 if absent)

If `PR_NUMBER` is missing or not a number, inform the user and stop.

## Step 1 — Fetch the PR Branch

Try remote ref conventions in order, stopping at the first success:

```bash
# GitHub / Gitea / Forgejo
git fetch origin "refs/pull/${PR_NUMBER}/head:pr/${PR_NUMBER}-review"

# GitLab / Bitbucket
git fetch origin "refs/merge-requests/${PR_NUMBER}/head:mr/${PR_NUMBER}-review"
```

On success, record the local tracking branch name (`pr/<N>-review` or `mr/<N>-review`) as `PR_BRANCH`.

If both fetches fail, report the error clearly (the remote may not expose PR refs, or the number may not exist). Ask the user to provide the branch name directly and stop — do not guess.

## Step 2 — Resolve the Base

- If `BASE` was provided as the second argument, use it as-is.
- Otherwise use the current branch: `git rev-parse --abbrev-ref HEAD`
- If the current branch is the same as the remote default branch (user is already on `main`), fall back to auto-detecting the remote default: `git remote show origin 2>/dev/null | grep 'HEAD branch' | awk '{print $NF}'`; default to `main` if that also fails.

## Step 3 — Find the Merge Base

```bash
git merge-base "$BASE" "$PR_BRANCH"
```

Store the result as `MERGE_BASE`. Use `$MERGE_BASE..$PR_BRANCH` for all subsequent diff and log commands — this is correct even when the local `$BASE` ref is behind the remote.

If `git log --oneline "$MERGE_BASE".."$PR_BRANCH"` produces no output, inform the user that the PR branch has no commits ahead of the base and stop.

## Step 4 — Gather Context

Run all three commands before beginning analysis:

```bash
# Commit list
git log --oneline "$MERGE_BASE".."$PR_BRANCH"

# File-level summary
git diff --stat "$MERGE_BASE".."$PR_BRANCH"

# Full unified diff
git diff "$MERGE_BASE".."$PR_BRANCH"
```

## Step 5 — Read Changed Files

For every file listed in the `--stat` output that is readable (not deleted, not binary), use the Read tool to load the current version from disk. This provides full file context beyond the diff hunks, making it possible to judge surrounding logic, imports, and tests.

Limit individual file reads to files under 500 lines. For larger files, read only the regions surrounding changed hunks — use line-number awareness from the diff `@@` markers.

## Step 6 — Write the Review

Structure the output as follows. Be specific — cite file paths and line numbers from the diff. Avoid generic observations that apply to any codebase.

### Summary

One to three sentences: what this PR does, how many commits, how many files changed, and whether the overall change looks well-scoped.

### Commits

List each commit from `git log --oneline` with a one-line assessment of whether its message is clear and its scope is coherent. Flag fixup commits, vague messages ("fix stuff"), or oversized commits that mix unrelated concerns.

### Per-File Analysis

For each changed file, a subsection with:

- **What changed** — a neutral description of the diff
- **Concerns** — correctness bugs, security issues, missing error handling, broken tests, API contract violations, logic errors. Omit this heading if none.
- **Suggestions** — non-blocking style, naming, structure, or documentation improvements. Omit this heading if none.

Order files by severity of concerns (highest first). Files with no concerns and no suggestions may be grouped under a single "No issues found" bullet list at the end.

### Overall Assessment

One of:
- **Looks good** — Ready to merge as-is or with minor nits addressed.
- **Needs minor changes** — Specific non-blocking items listed; can merge after addressing them.
- **Needs major changes** — Blocking issues that must be resolved before merge, summarized clearly.

List any cross-cutting concerns (e.g., missing tests for new logic, inconsistent error handling across multiple files, performance implications) that do not fit neatly into a single file's section.

## Edge Cases

- **Fetch failure**: remote does not expose PR refs → ask user for the branch name directly
- **Deleted files**: note in per-file section; no Read needed
- **Binary files** (images, lock files, compiled assets): note by name; skip content analysis
- **Renamed files**: treat as a move; focus analysis on content changes within the rename
- **Large diffs** (500+ files changed): summarize at directory level; note that full per-file analysis requires narrowing scope
- **Merge commits in history**: flag as a concern if they suggest a tangled branch history
- **No remote / offline**: Step 1 will fail; ask user to provide the branch name directly
