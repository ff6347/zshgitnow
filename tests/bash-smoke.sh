#!/bin/bash
# ABOUTME: Smoke-checks the executable GitNow commands from non-interactive Bash.
# ABOUTME: Verifies argument quoting, symlink resolution, and Git exit statuses.
# Child-shell expressions and injection fixtures must remain literal here.
# shellcheck disable=SC2016

set -euo pipefail
root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
fail() { printf 'FAIL: %s\n' "$*" >&2; exit 1; }
[[ -x "$root/bin/gitnow" ]] || fail 'executable launcher is missing'
sandbox=$(mktemp -d)
trap 'rm -rf -- "$sandbox"' EXIT
checkout="$sandbox/checkout with spaces"
mkdir -p "$checkout" "$sandbox/links"
cp -R "$root/gitnow.plugin.zsh" "$root/commands" "$root/bin" "$checkout/"
ln -s "$checkout/bin/state" "$sandbox/links/state"
export PATH="$checkout/bin:$PATH"
unset BASH_ENV
export GIT_CONFIG_NOSYSTEM=1 GIT_CONFIG_GLOBAL=/dev/null
export GIT_AUTHOR_NAME='Smoke Check' GIT_AUTHOR_EMAIL='smoke@example.invalid'
export GIT_COMMITTER_NAME=$GIT_AUTHOR_NAME GIT_COMMITTER_EMAIL=$GIT_AUTHOR_EMAIL
export GIT_TERMINAL_PROMPT=0 GIT_MERGE_AUTOEDIT=no
run() { bash --noprofile --norc -c "$@"; }

[[ $(run 'gitnow --version') == 'zshgitnow 0.1.0' ]] || fail 'version launcher'
for name in gitnow stage commit pull push state unstage show untracked commit-all upstream logs branch feature hotfix bugfix release move merge assume tag github bitbucket; do
  [[ $(run 'type -t "$1"' smoke "$name") == file ]] || fail "$name must be an executable, not a function or alias"
done

command git init --quiet --bare --initial-branch=main "$sandbox/remote.git"
command git init --quiet --initial-branch=main "$sandbox/work"
cd "$sandbox/work"
command git remote add origin "$sandbox/remote.git"
filename='file name;$HOME.txt'
message='Spaces "quotes" $HOME $(touch INJECTED) ; *'
printf 'base\n' > "$filename"
run 'stage -- "$1" && commit --quiet -m "$2"' smoke "$filename" "$message"
[[ $(command git log -1 --format=%s) == "$message" && ! -e INJECTED ]] || fail 'arguments must remain literal'
[[ -z $(command git status --porcelain) ]] || fail 'stage and commit run in caller directory'
run 'push'
[[ $(command git rev-parse --abbrev-ref '@{upstream}') == origin/main ]] || fail 'push sets tracking'

command git clone --quiet "$sandbox/remote.git" "$sandbox/peer"
printf 'remote\n' > "$sandbox/peer/remote.txt"
command git -C "$sandbox/peer" add remote.txt
command git -C "$sandbox/peer" commit --quiet -m Remote
command git -C "$sandbox/peer" push --quiet
run 'pull'
[[ -f remote.txt ]] || fail 'pull updates caller checkout'
[[ $(run '"$1"' smoke "$sandbox/links/state") == *main* ]] || fail 'launcher resolves chained external symlinks'
[[ $(run 'tag --latest') == '' ]] || fail 'tag dispatches to plugin function'
run 'feature "Some Work"'
[[ $(command git branch --show-current) == feature/some_work ]] || fail 'branch launcher'
run 'move main'

expected=0
command git commit --gitnow-invalid-option > "$sandbox/expected" 2>&1 || expected=$?
actual=0
run 'commit --gitnow-invalid-option' > "$sandbox/actual" 2>&1 || actual=$?
[[ $actual == "$expected" && $actual != 0 ]] || fail 'launcher preserves Git exit status'
cmp "$sandbox/expected" "$sandbox/actual" || fail 'launcher preserves Git diagnostics'

for name in unknown _gitnow_sync; do
  ln -s "$checkout/bin/gitnow" "$sandbox/links/$name"
  actual=0
  run '"$1"' smoke "$sandbox/links/$name" > "$sandbox/error" 2>&1 || actual=$?
  [[ $actual == 2 ]] || fail 'unknown and private launcher names must be rejected'
  grep -q 'unknown launcher' "$sandbox/error" || fail 'invalid launcher includes diagnostic'
done

printf 'Bash launcher smoke checks passed.\n'
