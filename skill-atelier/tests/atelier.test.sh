#!/usr/bin/env bash
# Smoke test for .local/bin/atelier. Run: bash tests/atelier.test.sh
# Builds a throwaway git repo with a fake run and checks exit code + first line of each subcommand.

set -uo pipefail

HERE=$(cd "$(dirname "$0")" && pwd)
SF="$HERE/../.local/bin/atelier"
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT
cd "$TMP"

pass=0
fail=0
out=""

# check <name> <expected-exit> <first-line-regex> <command...>
check() {
  local name=$1 want=$2 re=$3 rc=0
  shift 3
  out=$("$@" 2>&1) || rc=$?
  if [ "$rc" -eq "$want" ] && printf '%s\n' "$out" | sed -n '1p' | grep -qE -- "$re"; then
    pass=$((pass + 1))
  else
    fail=$((fail + 1))
    echo "FAIL $name: exit $rc (want $want), output:"
    printf '%s\n' "$out" | sed 's/^/    /'
  fi
}

# has <name> <regex>: the last output contains the regex
has() {
  if printf '%s\n' "$out" | grep -qE -- "$2"; then pass=$((pass + 1)); else fail=$((fail + 1)); echo "FAIL $1: output lacks /$2/:"; printf '%s\n' "$out" | sed 's/^/    /'; fi
}

git init -q -b main .
git config user.email t@example.com
git config user.name t
mkdir -p src
printf 'class Foo {\n  int bar() { return 1; }\n}\n' > src/Foo.java
printf 'class FooTest {\n  @Test void whenX_thenY() { assertThat(1).isEqualTo(1); }\n}\n' > src/FooTest.java
git add -A && git commit -q -m init

ID=T-1
RUN=.atelier/runs/$ID

check "help" 0 '^Usage:' "$SF" help
check "clock" 0 '^[0-9]+$' "$SF" clock
check "no run dir" 2 '^error:' "$SF" state nope get phase

# init / state
check "init" 0 '^result=ok' "$SF" init "$ID" "T-1 add baz"
check "init twice" 1 '^result=exists' "$SF" init "$ID" "T-1 add baz"
grep -qxF '.atelier/' .git/info/exclude && pass=$((pass + 1)) || { fail=$((fail + 1)); echo "FAIL exclude"; }
check "state set" 0 '^$' "$SF" state "$ID" phase=plan base_branch=main 'verify_cmd=true' 'lint_cmd=-' 'note=a=b'
check "state get" 0 '^plan$' "$SF" state "$ID" get phase
check "state get cmd" 0 '^true$' "$SF" state "$ID" get verify_cmd
check "state get note" 0 '^a=b$' "$SF" state "$ID" get note
check "state unknown key" 2 '^error:' "$SF" state "$ID" bogus=1
check "counter +1" 0 '^$' "$SF" state "$ID" verify_failures=+1
check "counters" 0 'amendments=0 verify_failures=1 review_rounds=0' "$SF" state "$ID" get counters

# log
T0=$("$SF" clock)
check "log" 0 '^row=1 duration=[0-9]+s$' "$SF" log "$ID" explore atelier-explorer explore ok haiku 1200 7 "$T0"
check "log n/a" 0 '^row=2 duration=\?$' "$SF" log "$ID" plan atelier-planner plan ok opus n/a n/a -
check "tokens summed" 0 '^1200$' "$SF" state "$ID" get subagent_tokens

# fake plan
cat > $RUN/plan.md <<'EOF'
# Plan: add baz
Type: feature

## Goal
Add baz.

## Acceptance criteria
1. baz returns 2
2. baz rejects null

## Steps
### Step 1 — src/Foo.java (modify)
- add baz
- signature: `int baz(String s)`

### Step 2 — src/Baz.java (new)
- new class

## Test cases
| # | AC | Test (file :: name) | Given | When | Then |
|---|---|---|---|---|---|
| 1 | 1 | src/FooTest.java :: whenX_thenY | a | b | c |
| 2 | 2 | src/FooTest.java :: whenNull_thenThrow | a | b | c |

## Verify
`true`

## Git
- branch: `feat/T-1`
EOF
check "validate plan fails (no digest row)" 1 '^result=invalid' "$SF" validate "$ID" plan.md atelier-writer
check "validate plan" 0 '^result=ok file=plan.md' "$SF" validate "$ID" plan.md atelier-planner
printf '# x\n' > $RUN/digest.md
check "validate digest" 1 '^result=invalid' "$SF" validate "$ID" digest.md atelier-planner
has "validate digest heading" "lacks '## Git'"
grep -qE '^\| 2 \| plan \| atelier-planner \| plan \| invalid ' $RUN/usage.md && pass=$((pass + 1)) || { fail=$((fail + 1)); echo "FAIL validate did not mark the row invalid"; }

# plan gate: AC 2 is covered; signature baz is missing in Foo.java (warning); Baz.java does not exist (ok)
check "plan-gate" 0 '^result=ok misses=0 warnings=1' "$SF" plan-gate "$ID"
sed -i.bak 's/^| 2 | 2 |/| 2 | 1 |/' $RUN/plan.md
check "plan-gate AC miss" 1 '^result=miss misses=1' "$SF" plan-gate "$ID"
has "plan-gate AC text" 'AC 2 has no test case'
sed -i.bak 's/^| 2 | 1 |/| 2 | 2 |/' $RUN/plan.md
rm -f $RUN/plan.md.bak

# amendments
cat > $RUN/plan-amendment-1.md <<'EOF'
# Amendment 1 (amend)
Scope change: no

## Cause
x

## Changes to the plan
- replace step 1 — src/Missing.java (modify): use other file
EOF
check "amendments" 0 '^amendments=1 next=2$' "$SF" amendments "$ID"
check "amendments counter" 0 'amendments=1 verify_failures=1' "$SF" state "$ID" get counters
check "plan-gate amendment" 1 '^result=miss misses=1' "$SF" plan-gate "$ID" --amendment 1
rm $RUN/plan-amendment-1.md

# gates: change an allowed file and an out-of-scope file
git switch -q -c feat/T-1
printf 'class Foo {\n  int bar() { return 1; }\n  int baz(String s) { return 2; }\n}\n' > src/Foo.java
printf 'class FooTest {\n  @Test void whenX_thenY() { assertThat(1).isEqualTo(1); }\n  @Test void whenNull_thenThrow() { }\n}\n' > src/FooTest.java
check "gates pass" 0 '^result=pass scope=0 tests=0 weakened=0' "$SF" gates "$ID"
check "gates state" 0 '^pass$' "$SF" state "$ID" get gates
printf 'x\n' > src/Other.java
check "gates scope" 1 '^result=fail scope=1' "$SF" gates "$ID"
has "gates scope text" 'src/Other.java is not in the plan'
rm src/Other.java
printf 'class FooTest {\n  @Test @Disabled void whenX_thenY() { }\n  @Test void whenNull_thenThrow() { }\n}\n' > src/FooTest.java
check "gates skip marker" 1 'weakened=[1-9]' "$SF" gates "$ID"
printf 'class FooTest {\n  @Test void whenNull_thenThrow() { }\n}\n' > src/FooTest.java
check "gates test missing" 1 'tests=1' "$SF" gates "$ID"
printf 'class FooTest {\n  @Test void whenX_thenY() { assertThat(1).isEqualTo(1); }\n  @Test void whenNull_thenThrow() { }\n}\n' > src/FooTest.java

# review-diff / snapshot / recheck-diff
printf 'new\n' > src/Baz.java
check "snapshot" 0 '^[0-9a-f]{40}$' "$SF" snapshot "$ID"
check "review-diff" 0 '^lines=[0-9]+ tree=[0-9a-f]{40}$' "$SF" review-diff "$ID"
grep -q 'src/Baz.java' $RUN/review.diff && pass=$((pass + 1)) || { fail=$((fail + 1)); echo "FAIL review.diff lacks untracked file"; }
printf 'new2\n' > src/Baz.java
check "recheck-diff" 0 '^lines=[1-9][0-9]* tree=' "$SF" recheck-diff "$ID"

# preexisting dirty is excluded from the snapshot
printf 'dirty\n' > src/Dirty.java
"$SF" state "$ID" preexisting_dirty=src/Dirty.java > /dev/null
a=$("$SF" snapshot "$ID"); printf 'dirty2\n' > src/Dirty.java; b=$("$SF" snapshot "$ID")
[ "$a" = "$b" ] && pass=$((pass + 1)) || { fail=$((fail + 1)); echo "FAIL preexisting_dirty not excluded"; }
"$SF" state "$ID" preexisting_dirty=- > /dev/null
rm src/Dirty.java

# run: pass, fail with tail, skipped, timeout
check "run baseline pass" 0 '^result=pass exit=0 duration=[0-9]+s' "$SF" run "$ID" baseline
check "baseline state" 0 '^green$' "$SF" state "$ID" get baseline
"$SF" state "$ID" 'verify_cmd=echo "FAIL Tests run: 3, Failures: 1"; exit 3' > /dev/null
check "run verify fail" 1 '^result=fail exit=3' "$SF" run "$ID" verify+lint
has "run verify tail" 'FAIL Tests run'
"$SF" state "$ID" 'verify_cmd=sleep 10' > /dev/null
check "run timeout" 124 '^result=timeout exit=124' env ATELIER_TIMEOUT=1 "$SF" run "$ID" verify+lint
check "last_verify state" 0 '^timeout$' "$SF" state "$ID" get last_verify
"$SF" state "$ID" verify_cmd=none lint_cmd=- > /dev/null
check "run skipped" 0 '^result=skipped' "$SF" run "$ID" verify+lint
check "run full skipped" 0 '^result=skipped' "$SF" run "$ID" full

# preexisting: baseline red with the same error line
printf 'FAIL Tests run: 5, Failures: 2\n' > $RUN/baseline.log
printf 'FAIL Tests run: 9, Failures: 4\nok\n' > $RUN/verify.log
check "preexisting same" 0 '^result=preexisting new=0 preexisting=1' "$SF" preexisting "$ID"
printf 'FAIL Tests run: 9, Failures: 4\nERROR in Foo\n' > $RUN/verify.log
check "preexisting new" 1 '^result=new new=1 preexisting=1' "$SF" preexisting "$ID"
printf 'all fine\n' > $RUN/verify.log
check "preexisting unclassified" 1 '^result=unclassified' "$SF" preexisting "$ID"

# report
check "report short" 0 '^Subagent (tokens|duration)' "$SF" report "$ID" --short
check "report" 0 '^\| agent \| spawns' "$SF" report "$ID"
has "report counts" 'Counts: invalid=1 deviation=0 retry=0 amendments=1'
has "report commands" 'verify\+lint #1 fail'
has "report total" '^\| total \| 2 \| 1200 \|'

echo "passed: $pass, failed: $fail"
[ "$fail" -eq 0 ]
