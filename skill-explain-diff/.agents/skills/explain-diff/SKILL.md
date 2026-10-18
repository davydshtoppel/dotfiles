---
mode: 'agent'
description: 'Analyze code changes between two branches using pure git. Provide a feature branch; optionally provide a base branch (defaults to current branch). Produces an overview (purpose, scope, approach), Mermaid diagrams (sequence, class, flowchart), and categorized analysis (design, performance, concurrency, tests and testability, controversial points, clean code) with a verdict.'
tools: ['codebase', 'terminal']
---

# Explain Diff

Analyze and explain code changes between two branches using only git. Works with any git repository.

**Rule:** every git command MUST use the `--no-pager` flag (`git --no-pager <command>`) to prevent interactive pager prompts.

## Arguments

- First argument: `FEATURE_BRANCH` (required)
- Second argument: `BASE_BRANCH` (optional; defaults to current branch)

If `FEATURE_BRANCH` is missing, stop: `Usage: /explain-diff <feature-branch> [base-branch]`

## Workflow

### 1. Validate and Resolve Branches

Verify `FEATURE_BRANCH` exists:
```bash
git --no-pager rev-parse --verify "$FEATURE_BRANCH" 2>/dev/null
```
If this fails, inform the user the branch doesn't exist locally and stop.

Resolve `BASE_BRANCH`: use the second argument if provided, otherwise `git --no-pager rev-parse --abbrev-ref HEAD`.

### 2. Find the Merge Base

```bash
MERGE_BASE=$(git --no-pager merge-base "$BASE_BRANCH" "$FEATURE_BRANCH")
echo "$MERGE_BASE"
```

**Already-merged branch detection:** if the feature branch was already merged into the base via a merge commit, `FEATURE_BRANCH` is an ancestor of `BASE_BRANCH`, which makes the diff empty. Detect and compensate:

```bash
if git merge-base --is-ancestor "$FEATURE_BRANCH" "$BASE_BRANCH" 2>/dev/null; then
  MERGE_COMMIT=$(git --no-pager log --merges --ancestry-path --format="%H" "${FEATURE_BRANCH}..${BASE_BRANCH}" | tail -1)
  if [ -n "$MERGE_COMMIT" ]; then
    MERGE_BASE="${MERGE_COMMIT}^1"
  fi
fi
```

Use `$MERGE_BASE..$FEATURE_BRANCH` for all diffs. If `git --no-pager log --oneline` produces no output after this adjustment, stop and inform the user. If a squash or rebase merge was used, the original commits are not ancestors and cannot be reconstructed.

### 3. Gather Context

Run all commands before beginning analysis. Always read `--stat` first to understand scope before diving into the full diff:

```bash
git --no-pager log --oneline "$MERGE_BASE".."$FEATURE_BRANCH"
git --no-pager diff --stat "$MERGE_BASE".."$FEATURE_BRANCH"
git --no-pager diff "$MERGE_BASE".."$FEATURE_BRANCH"
```

Use `codebase` to read non-deleted, non-binary changed files. Limit reads to files under 500 lines; for larger files read only regions surrounding changed hunks.

### 4. Write the Analysis

**Overview** — cover all three:
- **Purpose** — why these changes exist; the problem being solved or feature being added
- **Scope** — commit count, file count, which areas of the codebase are affected
- **Approach** — the overall technical strategy (e.g., new abstraction layer, API migration, caching, refactor for testability)

**Diagrams** — include each type that is relevant; omit types that add no insight; omit all if the diff is trivial or 500+ files:
- `sequenceDiagram` — async flows, API calls, events, protocol interactions between components
- `classDiagram` — class structure, inheritance, composition, interface contracts
- `flowchart TD` — control flow, decision logic, data pipelines

**Analysis** — for each dimension, write a paragraph if there is something notable; omit the heading otherwise:
- **Design** — patterns, API contracts, abstractions, coupling/cohesion, SOLID adherence
- **Performance** — complexity changes, N+1 risks, caching, I/O, hot-path impact
- **Concurrency** — thread safety, race conditions, async correctness, shared mutable state
- **Tests and Testability** — test coverage of changed code, quality of new/modified tests, testability of new code, missing edge/error cases
- **Controversial Points** — non-obvious decisions that could be challenged, trade-offs without justification, surprising naming or structural choices
- **Clean Code** — naming, DRY, SRP, function length, error handling hygiene

**Verdict** — one of:
- **No issues** — correct and clean as-is
- **Minor suggestions** — non-blocking items noted above
- **Review required** — blocking concerns to address before merge
- **Breaking changes** — backwards-incompatible changes; specify what breaks

## Edge Cases

- Branch not found: stop and suggest `git fetch`
- No commits ahead of base: stop and inform user
- Already-merged (merge commit): detected via ancestry check; `MERGE_COMMIT^1` used as effective base
- Already-merged (squash/rebase): `FEATURE_BRANCH` is NOT an ancestor; diff works normally against merge base
- Deleted or binary files: note by name, skip content analysis
- Renamed files: focus on content changes within the rename
- Large diffs (500+ files): summarize at directory level; omit diagrams
