#!/usr/bin/env bash
# Regression harness for checkout-snapshot.sh, the restorable snapshot that polish-code and
# evaluate-findings ship in both editions. Run it after any change to the script:
#
#   bash tests/checkout-snapshot-harness.sh [first-seed] [last-seed]   (default 1 40)
#
# It checks that the four shipped copies are identical and runs deterministic edge cases.
# Each seed then builds a randomized repo, damages it, and restores it, asserting byte-exact
# recovery, survival of ignored data, an untouched outside directory, and the undo round trip.
# Exits non-zero on any failure. KEEP=1 stops at the first failing seed and keeps its repo.

set -u
HERE=$(cd "$(dirname -- "$0")" && pwd)
ROOT=$(cd "$HERE/.." && pwd)
SNAP=$ROOT/claude/skills/polish-code/scripts/checkout-snapshot.sh
FIRST=${1:-1}; LAST=${2:-40}
BASE=$(mktemp -d "${TMPDIR:-/tmp}/snapshot-harness.XXXXXX") && [ -d "$BASE" ] || { echo "FAIL: cannot create a temp directory"; exit 1; }
BASEP=$(cd "$BASE" && pwd -P)
# Never run capture inside a here-string word: bash 3.2 creates the here-string's temp file before
# expanding the word, in the current directory when /tmp is not writable, so capture would scan it.
FAIL=0
fail() { echo "FAIL: $*"; FAIL=$((FAIL+1)); }
snap() { bash "$SNAP" "$@"; }

ref_hash=$(git hash-object --no-filters "$SNAP")
for copy in claude/skills/evaluate-findings codex/skills/polish-code codex/skills/evaluate-findings; do
  [ "$(git hash-object --no-filters "$ROOT/$copy/scripts/checkout-snapshot.sh")" = "$ref_hash" ] || fail "$copy/scripts/checkout-snapshot.sh differs from the polish-code copy"
done

fp() { # every file outside the .git directories (ignored included) with content hash, exec bit, symlink target; plus index and HEAD
  git ls-files -s; git symbolic-ref -q HEAD; git rev-parse --verify -q HEAD
  find . -path ./.git -prune -o -path ./emb/.git -prune -o \( -type f -o -type l \) -print0 | sort -z | while IFS= read -r -d '' f; do
    if [ -L "$f" ]; then echo "L $(readlink "$f") $f"; else echo "F $(git hash-object --no-filters -- "$f") $([ -x "$f" ] && echo x) $f"; fi
  done
}
outside_fp() { find "$OUT" -type f -print0 | sort -z | xargs -0 git hash-object --no-filters --; }
new_repo() { # aborts the harness unless the repo was created inside $BASE
  /bin/rm -rf "$1"; mkdir -p "$1" && cd "$1" && { case $(pwd -P) in "$BASEP"/*) true;; *) false;; esac; } && git init -q -b main \
    && git config user.email t@t && git config user.name t && git config commit.gpgsign false || { echo "FAIL: cannot set up $1"; exit 1; }
}

# --- deterministic edge cases ---------------------------------------------------------------
P=$BASE/probe
case_repo() { new_repo "$P"; echo base > base.txt; git add -A; git commit -qm i; }
cap() { ST=$(snap capture 2>/dev/null); [ -n "$ST" ] || fail "$1: capture failed"; }
expect_file() { [ "$(cat -- "$1" 2>/dev/null)" = "$2" ] || fail "$3: $1 holds '$(cat -- "$1" 2>/dev/null)', expected '$2'"; }

case_repo; echo secret.env >> .git/info/exclude; echo S > secret.env; cap "info/exclude"
: > .git/info/exclude; echo dmg > base.txt; snap restore $ST >/dev/null 2>&1
expect_file secret.env S "ignored via info/exclude"; expect_file base.txt base "info/exclude: restore ran"

case_repo; mkdir .venv; echo '*' > .venv/.gitignore; echo L > .venv/lib.py; cap "self-ignoring directory"
/bin/rm .venv/.gitignore; echo dmg > base.txt; snap restore $ST >/dev/null 2>&1
expect_file .venv/lib.py L "self-ignoring directory"; expect_file base.txt base "self-ignoring directory: restore ran"

case_repo; mkdir emb; (cd emb && git init -q && echo W > work.txt); cap "embedded repository"
/bin/rm -rf emb/.git; echo dmg > base.txt; snap restore $ST >/dev/null 2>&1
expect_file emb/work.txt W "embedded repository"; expect_file base.txt base "embedded repository: restore ran"

case_repo; echo N1 > notes.txt; cap "modified then hidden"; echo N2 > notes.txt; echo notes.txt > .gitignore; echo dmg > base.txt
snap restore $ST >/dev/null 2>&1; expect_file notes.txt N2 "file modified then hidden"; expect_file base.txt base "modified then hidden: restore ran"

case_repo; cap "created file"; echo new > made.txt; mkdir -p newdir; echo n > newdir/f.txt
snap restore $ST >/dev/null 2>&1; [ -e made.txt ] || [ -e newdir ] && fail "file created after capture was not deleted"

case_repo; echo f1 > f.txt; git add f.txt; git commit -qm f; echo f2 > f.txt; cap "index only"; git add f.txt
OUTPUT=$(snap restore $ST 2>/dev/null); echo "$OUTPUT" | grep -qx 'INDEX f.txt' || fail "index-only repair not reported"
[ "$(git status --short)" = " M f.txt" ] || fail "index-only repair: status is '$(git status --short)'"

if locale -a 2>/dev/null | grep -qx 'en_US.UTF-8'; then     # a collating locale, whatever the caller exported
  usnap() { env LC_ALL=en_US.UTF-8 bash "$SNAP" "$@"; }
  case_repo; printf A1 > 'a①'; printf A2 > 'a②'; ST=$(usnap capture 2>/dev/null); printf X > 'a②'
  usnap verify $ST && fail "collating names: verify blind to a change"; usnap restore $ST >/dev/null 2>&1; expect_file 'a②' A2 "collating names"
else echo "NOTE: collating-names case not run: no en_US.UTF-8 locale"; fi

case_repo; CAPST=$(snap capture 2>/dev/null); read -r _ b c d e <<< "$CAPST"; snap check CHERRY_PICK_HEAD "$b" "$c" "$d" "$e" >/dev/null && fail "pseudoref REF accepted"
snap restore CHERRY_PICK_HEAD "$b" "$c" "$d" "$e" >/dev/null 2>&1; [ -e .git/CHERRY_PICK_HEAD ] && fail "pseudoref REF written"

case_repo; echo secret.env > .gitignore; git add .gitignore; git commit -qm g; echo KEY > secret.env; ST=$(snap capture 2>/dev/null)
: > .gitignore; git add secret.env; snap restore $ST >/dev/null 2>&1; expect_file secret.env KEY "ignored file un-ignored and staged"
snap verify $ST || fail "un-ignored and staged: verify after restore"

case_repo; echo A > a.txt; printf Q > '"\141.txt"'; git add -A; git commit -qm q; ST=$(snap capture 2>/dev/null)
printf Q2 > '"\141.txt"'; snap verify $ST && fail "quoted name: verify blind to a change"
snap restore $ST >/dev/null 2>&1; expect_file '"\141.txt"' Q "quoted name"; expect_file a.txt A "quoted name sibling"

case_repo; mkdir -- -d; echo a > -foo; echo b > -d/y; chmod +x -foo; git add -A; git commit -qm d; ST=$(snap capture 2>/dev/null)
echo X > -foo; echo Y > -d/y; chmod -- -x -foo; snap restore $ST >/dev/null 2>&1
expect_file -foo a "dash name"; expect_file -d/y b "dash directory"; [ -x -foo ] || fail "dash name: exec bit lost"

for odd in "$(printf 'n\nl')" "$(printf 'c\rr')"; do
  case_repo; printf K > "$odd"; ST=$(snap capture 2>"$BASE/err"); [ -n "$ST" ] || fail "newline/CR name: capture failed"
  grep -q '^SKIPPED ' "$BASE/err" || fail "newline/CR name: not reported as SKIPPED"
  printf D > "$odd"; git add -- "$odd"; OUTPUT=$(snap restore $ST 2>/dev/null); expect_file "$odd" D "newline/CR name left untouched"
  echo "$OUTPUT" | grep -qx 'INDEX "[nc]\\[nr][lr]"' || fail "newline/CR name: index repair not reported quoted"
  echo "$OUTPUT" | grep -vqE '^(UNDO|MOVED|INDEX|RESTORED|LEFT|FAILED) ' && fail "newline/CR name: output holds a line no status starts"
done

case_repo; c1=$(git rev-parse HEAD); git update-index --add --cacheinfo "160000,$c1,sm"; git commit -qm sm; cap "gitlink in the index"
git update-index --cacheinfo "160000,$(git commit-tree -m x "$(git write-tree)"),sm"; git config diff.ignoreSubmodules all
OUTPUT=$(snap restore $ST 2>/dev/null); echo "$OUTPUT" | grep -qx 'INDEX sm' || fail "gitlink index repair not reported under diff.ignoreSubmodules"

case_repo; Bb=$(echo PWN | git hash-object -w --stdin); t1=$(printf '100644 blob %s\tpre-commit\n' "$Bb" | git mktree)
t2=$(printf '040000 tree %s\thooks\n' "$t1" | git mktree); t3=$(printf '040000 tree %s\t.git\n' "$t2" | git mktree)
CAPST=$(snap capture 2>/dev/null); read -r a b c _ e <<< "$CAPST"; snap restore "$a" "$b" "$c" "$t3" "$e" >/dev/null 2>&1
[ -e .git/hooks/pre-commit ] && fail "crafted tree: wrote into .git"

case_repo; mkdir -p in out; echo i > in/i; echo o > out/o; git add -A; git commit -qm s; git sparse-checkout set in 2>/dev/null
echo x > ita.txt; git add -N ita.txt; ST=$(snap capture 2>/dev/null); echo dmg > base.txt; snap restore $ST >/dev/null 2>&1
[ "$(git status --short | tr '\n' ';')" = " A ita.txt;" ] || fail "index flags: status is '$(git status --short | tr '\n' ';')'"

case_repo; ST=$(snap capture 2>/dev/null); echo c2 > base.txt; git commit -qam c2; git switch -qc other
OUTPUT=$(snap restore $ST 2>/dev/null); echo "$OUTPUT" | grep -q '^MOVED refs/heads/main ' || fail "moved branch not reported"

case_repo; git switch -qc feature; ST=$(snap capture 2>/dev/null); git switch -q main; git branch -qD feature
OUTPUT=$(snap restore $ST 2>/dev/null); echo "$OUTPUT" | grep -qx 'MOVED refs/heads/feature none' || fail "recreated branch not reported as MOVED none"

case_repo; mkdir sub; echo s > sub/s.txt; echo '*.tmp' > sub/.gitignore; git add -A; git commit -qm s; cap "ancestor replaced"
/bin/rm -rf sub; echo junk > sub; OUTPUT=$(snap restore $ST 2>/dev/null)
echo "$OUTPUT" | grep -qx 'RESTORED sub' || fail "ancestor replaced by a file: removal not reported"
echo "$OUTPUT" | grep -qx 'LEFT sub' && fail "ancestor replaced by a file: reported LEFT though removed"
expect_file sub/s.txt s "ancestor replaced by a file"; snap verify $ST || fail "ancestor replaced by a file: verify after restore"

# every status line reports its own operation's outcome: each failure point below must not read as RESTORED or INDEX
case_repo; mkdir d; echo f > d/f.txt; git add -A; git commit -qm d; cap "failed write"
/bin/rm d/f.txt; chmod 555 d; OUTPUT=$(snap restore $ST 2>/dev/null); chmod 755 d
echo "$OUTPUT" | grep -qx 'FAILED d/f.txt' || fail "failed write not reported as FAILED"; echo "$OUTPUT" | grep -qx 'RESTORED d/f.txt' && fail "failed write reported as RESTORED"

case_repo; mkdir d; echo f > d/f.txt; git add -A; git commit -qm d; cap "failed delete"
echo n > d/new.txt; chmod 555 d; OUTPUT=$(snap restore $ST 2>/dev/null); chmod 755 d
echo "$OUTPUT" | grep -qx 'LEFT d/new.txt' || fail "failed delete not reported as LEFT"; expect_file d/new.txt n "failed delete"

case_repo; cap "index lock"; echo dmg > base.txt; git add base.txt; touch .git/index.lock
OUTPUT=$(snap restore $ST 2>/dev/null) && fail "index lock: restore exited 0"; /bin/rm -f .git/index.lock
echo "$OUTPUT" | grep -q '^INDEX ' && fail "index lock: INDEX reported without an index write"; expect_file base.txt dmg "index lock: restore stopped"

case_repo; cap "HEAD lock"; echo c2 > base.txt; git commit -qam c2; touch .git/refs/heads/main.lock
snap restore $ST >/dev/null 2>&1 && fail "HEAD lock: restore exited 0"; /bin/rm -f .git/refs/heads/main.lock; expect_file base.txt c2 "HEAD lock: restore stopped"

case_repo; git checkout -q -b b1; echo b1 > base.txt; git commit -qam b1; git checkout -q -; echo m > base.txt; git commit -qam m
git merge -q b1 >/dev/null 2>&1; snap capture >/dev/null 2>&1 && fail "unmerged index: capture succeeded"

cd "$BASE" && /bin/rm -rf "$P"

# --- randomized damage --------------------------------------------------------------------
for r in $(seq "$FIRST" "$LAST"); do
  RANDOM=$((r*7919)); SEEDFAIL=$FAIL
  D=$BASE/r$r; OUT=$BASE/out$r; /bin/rm -rf "$OUT"; mkdir -p "$OUT"; echo keep > "$OUT/.gitignore"; echo keep > "$OUT/n.txt"
  new_repo "$D" || exit 1
  git config filter.up.clean 'tr a-z A-Z'; git config filter.up.smudge cat
  names=("-x.txt" "-d/y.txt" "a.txt" "b c.txt" "d/e.dat" "d/f g.txt" "h.sh" "i.txt" "j/k/l.txt" "m.dat" "sub/n.txt" "sub/deep/o.txt" "z.bad")
  for n in "${names[@]}"; do mkdir -p -- "$(dirname -- "$n")"; printf 'v1 %s\r\nline2\n' "$RANDOM" > "$n"; done
  chmod +x h.sh; ln -s a.txt link; ln -s sub linkdir
  printf 'secret.env\nnode_modules/\n*.log\n' > .gitignore; printf '*.tmp\n' > sub/.gitignore
  UNBORN=$((RANDOM%5==0))
  [ $UNBORN = 0 ] && { git add -A; git commit -qm init; }
  printf '*.txt text eol=crlf\n*.bad filter=bad\n' > .gitattributes
  printf '*.dat filter=up\n' > .git/info/attributes
  git config filter.bad.clean false; git config filter.bad.required true
  [ $((RANDOM%2)) = 0 ] && git config core.autocrlf true
  printf 'KEY=%s\n' "$RANDOM" > secret.env; mkdir -p node_modules/pkg; printf 'mod %s\n' "$RANDOM" > node_modules/pkg/x.js; echo log > app.log; echo tmp > sub/x.tmp
  mkdir -p emb && (cd emb && git init -q && echo e > e.txt)
  [ $UNBORN = 0 ] && [ $((RANDOM%2)) = 0 ] && git checkout -q --detach 2>/dev/null
  for n in "${names[@]}" "u1.txt" "u 2.dat" "x/u3.txt" "s1.txt"; do
    case $((RANDOM%7)) in
      0) mkdir -p -- "$(dirname -- "$n")"; printf 'staged %s\n' "$RANDOM" > "$n"; git add -- "$n" 2>/dev/null;;
      1) mkdir -p -- "$(dirname -- "$n")"; printf 'unst %s\r\nx\n' "$RANDOM" > "$n";;
      2) mkdir -p -- "$(dirname -- "$n")"; printf 'st %s\n' "$RANDOM" > "$n"; git add -- "$n" 2>/dev/null; printf 'then unst lf %s\n' "$RANDOM" > "$n";;
      3) git rm -q -f --ignore-unmatch -- "$n" 2>/dev/null;;
      4) /bin/rm -f -- "$n";;
      *) :;;
    esac
  done
  mkdir -p .turbo; echo t > .turbo/t
  IGNORED="secret.env node_modules/pkg/x.js app.log sub/x.tmp"
  ign_sums() { for f in $IGNORED; do [ "$f" = "$IGNDEL" ] || echo "$f $(git hash-object --no-filters -- "$f" 2>&1)"; done; }
  IGNDEL=__none__; BEFORE=$(fp); OB=$(outside_fp); IGNSUM=$(ign_sums)
  CAPST=$(snap capture 2>/dev/null); read -r REF COMMIT IDX RAW HID <<< "$CAPST"
  [ "$BEFORE" = "$(fp)" ] || fail "run $r: capture changed the checkout"
  for n in "${names[@]}" "u1.txt" "u 2.dat" "x/u3.txt" "s1.txt" "new1.txt" "y/new 2.dat" "link" "linkdir"; do
    case $((RANDOM%10)) in
      0) mkdir -p -- "$(dirname -- "$n")"; /bin/rm -f -- "$n"; printf 'dmg %s\n' "$RANDOM" > "$n";;
      1) mkdir -p -- "$(dirname -- "$n")"; /bin/rm -f -- "$n"; printf 'dmg-st %s\n' "$RANDOM" > "$n"; git add -- "$n" 2>/dev/null;;
      2) /bin/rm -f -- "$n";;
      3) git rm -q --cached --ignore-unmatch -- "$n" 2>/dev/null;;
      4) [ -f "$n" ] && [ ! -L "$n" ] && chmod +x "$n";;
      5) [ -e "$n" ] && { /bin/rm -f -- "$n"; ln -s target.txt "$n"; };;
      6) [ -f "$n" ] && [ ! -L "$n" ] && { /bin/rm -f -- "$n"; mkdir -p -- "$n"; echo inner > "$n/inner.txt"; };;
      *) :;;
    esac
  done
  IGNDEL=__none__                                    # ignored file the damage itself destroys (not restorable)
  case $((RANDOM%5)) in
    0) : > .gitignore;;
    1) printf 'new1.txt\n' >> .gitignore;;
    2) /bin/rm -rf sub; IGNDEL=sub/x.tmp;;
    3) /bin/rm -rf sub; ln -s "$OUT" sub; IGNDEL=sub/x.tmp;;   # an ancestor becomes a symlink out of the repo
    *) :;;
  esac
  echo target > target.txt; echo e2 > emb/e.txt
  [ $((RANDOM%3)) = 0 ] && { git -c filter.bad.required=false add -A -- . ':(exclude)emb' >/dev/null 2>&1; git commit -qm dmg >/dev/null 2>&1; }
  [ $((RANDOM%5)) = 0 ] && git checkout -q -b other 2>/dev/null
  DAMAGED=$(fp)
  OUTPUT=$(snap restore "$REF" "$COMMIT" "$IDX" "$RAW" "$HID" 2>/dev/null)
  read -r _ UREF UCOMMIT UIDX URAW UHID <<< "$(echo "$OUTPUT" | grep '^UNDO ')"
  LEFT=$(echo "$OUTPUT" | sed -n 's/^LEFT //p')
  [ "$OB" = "$(outside_fp)" ] || fail "run $r: files outside the repo changed"
  [ "$(ign_sums)" = "$(echo "$IGNSUM" | grep -v -F "$IGNDEL ")" ] || fail "run $r: ignored data lost"
  { echo "$LEFT" | grep . || echo __none__; } | sed 's#^#./#' > "$D.left"; echo "emb/e.txt" >> "$D.left"; echo "./$IGNDEL" >> "$D.left"
  [ "$(echo "$BEFORE" | grep -v -F -f "$D.left")" = "$(fp | grep -v -F -f "$D.left")" ] || fail "run $r (unborn=$UNBORN): restore mismatch"
  if [ -z "$LEFT" ] && ! snap verify "$REF" "$COMMIT" "$IDX" "$RAW" "$HID"; then fail "run $r: verify after restore"; fi
  LEFT2=$(snap restore "$UREF" "$UCOMMIT" "$UIDX" "$URAW" "$UHID" 2>/dev/null | sed -n 's/^LEFT //p')
  if [ -z "$LEFT2" ] && [ "$DAMAGED" != "$(fp)" ]; then fail "run $r: undo mismatch"; fi
  [ "$OB" = "$(outside_fp)" ] || fail "run $r: files outside the repo changed on undo"
  [ -n "${KEEP:-}" ] && [ "$FAIL" -gt "$SEEDFAIL" ] && { echo "kept $D"; exit 1; }
  cd "$BASE"; /bin/rm -rf "$D" "$D.left" "$OUT"
done

cd /; /bin/rm -rf "$BASE"
[ $FAIL = 0 ] && echo "checkout-snapshot harness: seeds $FIRST-$LAST and edge cases passed"
[ $FAIL = 0 ]
