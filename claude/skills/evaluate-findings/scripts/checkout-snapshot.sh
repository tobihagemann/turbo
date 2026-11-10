#!/usr/bin/env bash
# Restorable snapshot of a git checkout: HEAD, the index, and every non-ignored
# working-tree file outside .turbo/, hashed byte-exact without content filters.
# Identical copies ship in polish-code and evaluate-findings of both editions.
# Change them together, then run `bash tests/checkout-snapshot-harness.sh`.
#
# A state is five space-separated values: REF COMMIT IDX RAW HID
#   REF     full symbolic ref of HEAD, or "-" when detached
#   COMMIT  HEAD's commit, or "unborn"
#   IDX     tree of the index
#   RAW     tree of the raw working tree
#   HID     blob listing the paths on disk that RAW leaves out: ignored files and directories,
#           gitlinks, embedded repositories, tracked paths now holding a directory, and
#           names with a newline or CR
#
# Usage, from anywhere inside the repo:
#   checkout-snapshot.sh capture
#       Prints the current state. Names each path it cannot hold (gitlinks, embedded
#       repositories, tracked paths now holding a directory, names with a newline or CR)
#       on stderr as "SKIPPED <path>". Exits 1 with a message on stderr when it cannot
#       write its objects, such as with an unmerged index.
#   checkout-snapshot.sh check STATE
#       Exits 0 when REF is "-" or a well-formed branch name under refs/heads/, the state's
#       objects still exist, and its trees hold only paths git checks out; otherwise prints
#       "INVALID <value>" or "LOST <id>" and exits 1.
#   checkout-snapshot.sh restore STATE
#       Returns the checkout to the given state, printing:
#         UNDO <state>            the state found before any write, printed first
#         MOVED <ref> <old|none>  a branch HEAD did not name, with its prior commit, printed
#                                 before the move or creation is attempted
#         INDEX <path>            each index entry it changed, quoted as git quotes it
#         RESTORED <path>         each path it deleted or wrote
#         LEFT <path>             each path it left untouched: no state holds its current bytes,
#                                 it was on disk outside RAW at capture, the restored ignore
#                                 rules hide it, or removing it failed
#         FAILED <path>           each path whose write failed; its prior bytes survive only in UNDO
#       Exits 1 without writing when check fails or the current state cannot be captured.
#       Stops with exit 1 when it cannot move HEAD, write the index, or scan the working tree.
#       Restoring toward the UNDO state undoes the restore, apart from MOVED branches and
#       index flags on entries it rewrote. Judge the outcome with verify, not the exit status.
#   checkout-snapshot.sh verify STATE
#       Exits 0 when HEAD, the index tree, and a fresh raw tree match the state.
#
# The objects it writes are unreferenced, so `git gc` can prune them; `check` reports that.

set -u
: "${TMPDIR:=/tmp}"
top=$(git rev-parse --show-toplevel) || exit 1
cd "$top" || exit 1
nl='
'
cr=$(printf '\r')

behind_symlink() { # true when an ancestor directory of $1 is a symlink
  local d=$1
  while [ "${d%/*}" != "$d" ]; do d=${d%/*}; [ -L "$d" ] && return 0; done
  return 1
}

snap_raw() { # $1 optional file the SKIPPED paths are appended to; prints the raw tree; fails when an object cannot be written
  local T L R S P tree ok=1 skip=${1:-/dev/null}
  T=$(mktemp -u "$TMPDIR/idx.XXXXXX"); L=$(mktemp "$TMPDIR/ls.XXXXXX")
  R=$(mktemp "$TMPDIR/reg.XXXXXX"); S=$(mktemp "$TMPDIR/sorted.XXXXXX"); P=$(mktemp "$TMPDIR/info.XXXXXX")
  git ls-files -z -c -o --exclude-standard -- . ':(exclude).turbo' > "$L"
  env LC_ALL=C sort -zu "$L" > "$S"                  # byte order: a locale can collate distinct names as equal
  while IFS= read -r -d '' p; do
    case $p in *"$nl"*|*"$cr"*) echo "SKIPPED $p" >&2; printf '%s\0' "$p" >> "$skip"; continue;; esac
    behind_symlink "$p" && continue                  # git never records paths beyond a symlink
    if [ -L "$p" ]; then
      printf '120000 %s\t%s\0' "$(printf %s "$(readlink -- "$p")" | git hash-object -w --stdin)" "$p" >> "$P"
    elif [ -d "$p" ]; then
      echo "SKIPPED ${p%/}" >&2; printf '%s\0' "${p%/}/" >> "$skip"   # gitlink, embedded repository, or tracked path now a directory
    elif [ -f "$p" ]; then
      printf '%s\0' "$p" >> "$R"
    fi                                               # listed but gone from disk: not in the tree
  done < "$S"
  if [ -s "$R" ]; then                               # literal path arguments: --stdin-paths would unquote them
    xargs -0 git hash-object -w --no-filters -- < "$R" > "$L" || ok=
    exec 3< "$L"
    while IFS= read -r -d '' p; do
      IFS= read -r h <&3
      if [ -x "$p" ]; then m=100755; else m=100644; fi
      printf '%s %s\t%s\0' "$m" "$h" "$p" >> "$P"
    done < "$R"
    exec 3<&-
  fi
  GIT_INDEX_FILE=$T git read-tree --empty || ok=
  if [ -s "$P" ]; then GIT_INDEX_FILE=$T git update-index -z --index-info < "$P" || ok=; fi
  tree=$(GIT_INDEX_FILE=$T git write-tree) || ok=
  /bin/rm -f "$T" "$L" "$R" "$S" "$P"
  [ -n "$ok" ] && echo "$tree"
}

index_tree() { # tree of the real index without writing it (writing re-checks racily clean entries through clean filters)
  local T tree ok=1; T=$(mktemp -u "$TMPDIR/idx.XXXXXX")
  GIT_INDEX_FILE=$T git read-tree --empty || ok=
  git ls-files -s -z | GIT_INDEX_FILE=$T git update-index -z --index-info || ok=
  tree=$(GIT_INDEX_FILE=$T git write-tree) || ok=
  /bin/rm -f "$T"
  [ -n "$ok" ] && echo "$tree"
}

capture() {
  local ref commit idx raw hid H
  ref=$(git symbolic-ref -q HEAD || echo -)
  commit=$(git rev-parse --verify -q HEAD || echo unborn)
  idx=$(index_tree) || { echo "capture failed: cannot write the index tree (unmerged entries?)" >&2; return 1; }
  H=$(mktemp "$TMPDIR/hid.XXXXXX")
  git ls-files -z -o -i --exclude-standard --directory -- . ':(exclude).turbo' > "$H"
  raw=$(snap_raw "$H") || { /bin/rm -f "$H"; echo "capture failed: cannot write the working-tree tree" >&2; return 1; }
  hid=$(git hash-object -w --stdin < "$H") || { /bin/rm -f "$H"; echo "capture failed: cannot write the left-out path list" >&2; return 1; }
  /bin/rm -f "$H"
  echo "$ref $commit $idx $raw $hid"
}

check_state() { # $1 REF $2 COMMIT $3 IDX $4 RAW $5 HID
  local o T
  case $1 in
    -) ;;
    refs/heads/*) git check-ref-format "$1" || { echo "INVALID $1"; return 1; };;
    *) echo "INVALID $1"; return 1;;
  esac
  for o in "$3" "$4"; do git cat-file -e "$o^{tree}" 2>/dev/null || { echo "LOST $o"; return 1; }; done
  git cat-file -e "$5^{blob}" 2>/dev/null || { echo "LOST $5"; return 1; }
  [ "$2" = unborn ] || git cat-file -e "$2^{commit}" 2>/dev/null || { echo "LOST $2"; return 1; }
  T=$(mktemp -u "$TMPDIR/idx.XXXXXX")
  for o in "$3" "$4"; do                              # read-tree refuses .git, .. and other paths git never checks out
    GIT_INDEX_FILE=$T git read-tree "$o" 2>/dev/null || { /bin/rm -f "$T"; echo "INVALID $o"; return 1; }
  done
  /bin/rm -f "$T"
}

was_hidden() { # $1 path, $2 left-out list: true when the path, or a directory above it, was on disk outside the raw tree
  local d=$1
  grep -qzxF -- "$d" "$2" && return 0
  while [ "${d%/*}" != "$d" ]; do d=${d%/*}; grep -qzxF -- "$d/" "$2" && return 0; done
  return 1
}

prune_up() { local d=$1; while [ "${d%/*}" != "$d" ]; do d=${d%/*}; rmdir -- "$d" 2>/dev/null || return 0; done; }

clear_ancestors() { # $1 path, $2 undo raw tree: unlink file/symlink ancestors the undo tree holds
  local acc= c parts
  IFS=/ read -ra parts <<< "$1"
  unset 'parts[${#parts[@]}-1]'
  for c in ${parts[@]+"${parts[@]}"}; do
    acc=${acc:+$acc/}$c
    if [ -L "$acc" ] || { [ -e "$acc" ] && [ ! -d "$acc" ]; }; then
      if git cat-file -e "$2:$acc" 2>/dev/null && /bin/rm -f -- "$acc"; then echo "RESTORED $acc"; else echo "LEFT $acc"; return 1; fi
    fi
  done
}

write_entry() { # $1 target raw tree, $2 mode, $3 path, $4 undo raw tree
  local p=$3 x=-x t
  clear_ancestors "$p" "$4" || return 0
  if [ -L "$p" ] || [ -f "$p" ]; then
    git cat-file -e "$4:$p" 2>/dev/null || { echo "LEFT $p"; return 0; }   # replace only bytes the undo state holds
    /bin/rm -f -- "$p" || { echo "LEFT $p"; return 0; }
  elif [ -d "$p" ]; then rmdir -- "$p" 2>/dev/null || { echo "LEFT $p"; return 0; }; fi
  [ "$2" = 100755 ] && x=+x                          # from here on, a failure leaves the prior bytes only in the UNDO state
  { case $p in */*) mkdir -p -- "${p%/*}";; esac; } \
    && if [ "$2" = 120000 ]; then t=$(git cat-file blob "$1:$p") && ln -s -- "$t" "$p"
       else git cat-file blob "$1:$p" > "$p" && chmod -- "$x" "$p"; fi \
    && echo "RESTORED $p" || echo "FAILED $p"
}

apply_entries() { # $1 target raw, $2 current raw, $3 undo raw, $4 target left-out list, $5 "ignore" to limit to .gitignore files
  local D meta p st mode; D=$(mktemp "$TMPDIR/diff.XXXXXX")
  git diff-tree -r -z --raw --no-renames "$1" "$2" > "$D"           # plumbing: no diff.* configuration applies
  while IFS= read -r -d '' meta && IFS= read -r -d '' p; do        # deletions first
    [ "${5:-}" = ignore ] && [ "${p##*/}" != .gitignore ] && continue
    st=${meta##* }; [ "$st" = A ] || continue
    if git cat-file -e "$3:$p" 2>/dev/null && ! was_hidden "$p" "$4" && /bin/rm -f -- "$p"; then
      prune_up "$p"; echo "RESTORED $p"
    else echo "LEFT $p"; fi
  done < "$D"
  while IFS= read -r -d '' meta && IFS= read -r -d '' p; do        # then writes, by the target's mode
    [ "${5:-}" = ignore ] && [ "${p##*/}" != .gitignore ] && continue
    st=${meta##* }; [ "$st" = A ] && continue
    mode=${meta#:}; mode=${mode%% *}
    write_entry "$1" "$mode" "$p" "$3"
  done < "$D"
  /bin/rm -f "$D"
}

report_hidden() { # $1 target raw, $2 current raw, $3 undo raw: paths the undo tree holds that the restored rules ignore again
  local D p; D=$(mktemp "$TMPDIR/hidden.XXXXXX")
  git diff-tree -r -z --name-only --no-renames --diff-filter=A "$1" "$3" > "$D"
  while IFS= read -r -d '' p; do
    git cat-file -e "$2:$p" 2>/dev/null && continue
    if [ -e "$p" ] || [ -L "$p" ]; then echo "LEFT $p"; fi
  done < "$D"
  /bin/rm -f "$D"
}

restore_state() {
  local ref=$1 commit=$2 idx=$3 raw=$4 hid=$5 undo uref uidx uraw cur old H
  check_state "$@" || return 1
  undo=$(capture) || return 1; echo "UNDO $undo"                               # undo handle, before any write
  read -r uref _ uidx uraw _ <<< "$undo"
  if [ "$ref" != - ] && [ "$ref" != "$uref" ]; then                            # the undo state names only HEAD's ref
    old=$(git rev-parse --verify -q "$ref") || old=none
    [ "$old" = none ] && [ "$commit" = unborn ] || [ "$old" = "$commit" ] || echo "MOVED $ref $old"
  fi
  if [ "$ref" = - ]; then git update-ref --no-deref HEAD "$commit"             # refs only: no checkout touches the index or files
  elif [ "$commit" = unborn ]; then git symbolic-ref HEAD "$ref" && { ! git rev-parse --verify -q "$ref" >/dev/null || git update-ref -d "$ref"; }
  else git symbolic-ref HEAD "$ref" && git update-ref "$ref" "$commit"; fi \
    || { echo "restore stopped: cannot move HEAD to the captured state" >&2; return 1; }
  H=$(mktemp "$TMPDIR/hid.XXXXXX"); git cat-file blob "$hid" > "$H"
  apply_entries "$raw" "$uraw" "$uraw" "$H" ignore                             # ignore files first
  # Then the index, so files only the current index tracks stay out of the scan below.
  # --reset keeps skip-worktree and intent-to-add flags on entries unchanged since capture.
  # States record no flags, so a flag cleared since capture stays cleared.
  # An unchanged index is not rewritten: writing re-checks racily clean entries through clean filters.
  [ "$uidx" = "$idx" ] || git read-tree --reset "$idx" \
    || { /bin/rm -f "$H"; echo "restore stopped after the ignore files: cannot write the index" >&2; return 1; }
  git -c core.quotePath=false diff-tree -r --name-only --no-renames "$uidx" "$idx" \
    | while IFS= read -r p; do echo "INDEX $p"; done   # git quotes a name holding a control character, quote, or backslash
  cur=$(snap_raw 2>/dev/null) || { /bin/rm -f "$H"; echo "restore stopped after the ignore files and index: cannot write the working-tree tree" >&2; return 1; }
  apply_entries "$raw" "$cur" "$uraw" "$H"                                     # everything else
  report_hidden "$raw" "$cur" "$uraw"
  /bin/rm -f "$H"
  git update-index -q --refresh >/dev/null 2>&1 || true                        # best-effort: a failing required clean filter must not fail the restore
}

verify_state() {
  [ "$(git symbolic-ref -q HEAD || echo -)" = "$1" ] && [ "$(git rev-parse --verify -q HEAD || echo unborn)" = "$2" ] \
    && [ "$(index_tree)" = "$3" ] && [ "$(snap_raw 2>/dev/null)" = "$4" ]
}

usage() { echo "usage: $0 capture | check|restore|verify REF COMMIT IDX RAW HID" >&2; exit 2; }

cmd=${1:-}; [ $# -gt 0 ] && shift
case $cmd in
  capture) [ $# -eq 0 ] || usage; capture;;
  check) [ $# -eq 5 ] || usage; check_state "$@";;
  restore) [ $# -eq 5 ] || usage; restore_state "$@";;
  verify) [ $# -eq 5 ] || usage; verify_state "$@";;
  *) usage;;
esac
