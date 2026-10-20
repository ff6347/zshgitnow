#!/bin/zsh
# ABOUTME: Smoke-checks GitNow commands against temporary local Git repositories.
# ABOUTME: Exercises staging, commits, upstream pushes, and rebasing with autostash.

emulate -LR zsh
setopt errexit nounset pipefail

plugin=${0:A:h:h}/gitnow.plugin.zsh
source "$plugin"

sandbox=$(mktemp -d)
trap 'rm -rf -- "$sandbox"' EXIT
# Keep the smoke check independent of personal Git settings and hooks.
export GIT_CONFIG_NOSYSTEM=1 GIT_CONFIG_GLOBAL=/dev/null
export GIT_AUTHOR_NAME='Smoke Check' GIT_AUTHOR_EMAIL='smoke@example.invalid'
export GIT_COMMITTER_NAME=$GIT_AUTHOR_NAME GIT_COMMITTER_EMAIL=$GIT_AUTHOR_EMAIL
export GIT_TERMINAL_PROMPT=0 GIT_MERGE_AUTOEDIT=no

fail() { print -u2 -- "FAIL: $*"; exit 1; }

command git init --quiet --bare --initial-branch=main "$sandbox/remote.git"
command git init --quiet --initial-branch=main "$sandbox/work"
cd "$sandbox/work"
command git remote add origin "$sandbox/remote.git"
mkdir subdir
print -r -- base > root.txt
print -r -- base > 'subdir/file with spaces.txt'
cd subdir
stage
[[ $(command git diff --cached --name-only) == 'subdir/file with spaces.txt' ]] || fail 'stage defaults to current directory'
cd ..
stage root.txt
commit --quiet -m 'Initial files'
[[ -z $(command git status --porcelain) ]] || fail 'commit staged files'
push
[[ $(command git rev-parse --abbrev-ref '@{upstream}') == origin/main ]] || fail 'push sets upstream'

command git clone --quiet "$sandbox/remote.git" "$sandbox/peer"
print -r -- remote > "$sandbox/peer/remote.txt"
command git -C "$sandbox/peer" add remote.txt
command git -C "$sandbox/peer" commit --quiet -m 'Remote change'
command git -C "$sandbox/peer" push --quiet

print -r -- local >> root.txt
stage root.txt
commit --quiet -m 'Local change'
print -r -- dirty >> 'subdir/file with spaces.txt'
pull
command git merge-base --is-ancestor origin/main HEAD || fail 'pull rebases local commits'
[[ $(command git diff --name-only) == 'subdir/file with spaces.txt' ]] || fail 'pull restores dirty tracked files'
[[ $(tail -n 1 'subdir/file with spaces.txt') == dirty ]] || fail 'autostash preserves contents'
pull main
pull origin main --quiet
stage
commit --quiet -m 'Preserve working changes'
push origin main

command git checkout --quiet -b topic
push origin HEAD:published
command git branch --quiet --set-upstream-to=origin/published
print -r -- topic >> root.txt
stage root.txt
commit --quiet -m 'Topic change'
push
[[ $(command git --git-dir="$sandbox/remote.git" rev-parse published) == $(command git rev-parse HEAD) ]] || fail 'push uses tracked branch name'
pull

if commit --gitnow-invalid-option > "$sandbox/error" 2>&1; then
  fail 'commit must propagate Git failures'
fi
[[ -s "$sandbox/error" ]] || fail 'Git failure includes diagnostic'
command git checkout --quiet --detach
if pull > "$sandbox/error" 2>&1; then
  fail 'inferred pull must reject detached HEAD'
fi
grep -q 'detached HEAD' "$sandbox/error" || fail 'detached HEAD includes diagnostic'

print -r -- 'Smoke checks passed.'
