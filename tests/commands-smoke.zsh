#!/bin/zsh
# ABOUTME: Smoke-checks the GitNow helper commands against real local repositories.
# ABOUTME: Verifies branches, stashes, tags, and hosting clones without network access.

emulate -LR zsh
setopt errexit nounset pipefail
source "${0:A:h:h}/gitnow.plugin.zsh"
sandbox=$(mktemp -d)
trap 'rm -rf -- "$sandbox"' EXIT
export GIT_CONFIG_NOSYSTEM=1 GIT_CONFIG_GLOBAL=/dev/null
export GIT_AUTHOR_NAME='Smoke Check' GIT_AUTHOR_EMAIL='smoke@example.invalid'
export GIT_COMMITTER_NAME=$GIT_AUTHOR_NAME GIT_COMMITTER_EMAIL=$GIT_AUTHOR_EMAIL
export GIT_TERMINAL_PROMPT=0 GIT_MERGE_AUTOEDIT=no GIT_EDITOR=true
fail() { print -u2 -- "FAIL: $*"; exit 1; }

[[ $(gitnow) == *commit-all* ]] || fail 'gitnow lists commands'
[[ $(gitnow --version) == *0.1.0* ]] || fail 'gitnow reports version'
command git init --quiet --bare --initial-branch=main "$sandbox/remote.git"
command git init --quiet --initial-branch=main "$sandbox/work"
cd "$sandbox/work"
command git remote add origin "$sandbox/remote.git"
print -r -- base > tracked.txt
print -r -- base > 'with spaces.txt'
stage
commit --quiet -m Initial
push

[[ $(state) == *main* ]] || fail 'state shows branch'
[[ $(show) == *Initial* ]] || fail 'show defaults to HEAD'
[[ $(show --format=%s --no-patch HEAD) == Initial ]] || fail 'show forwards arguments'
[[ $(logs -1) == *Initial* ]] || fail 'logs forwards arguments'
print -r -- untracked > extra.txt
[[ $(untracked) == *extra.txt* && -f extra.txt ]] || fail 'untracked is dry-run only'
stage extra.txt
unstage extra.txt
[[ -z $(command git diff --cached --name-only) ]] || fail 'unstage explicit file'
stage extra.txt
unstage
[[ -z $(command git diff --cached --name-only) ]] || fail 'unstage defaults to current directory'
assume 'with spaces.txt'
[[ $(command git ls-files -v 'with spaces.txt') == h* ]] || fail 'assume sets index bit'
assume --no-assume 'with spaces.txt'
[[ $(command git ls-files -v 'with spaces.txt') == H* ]] || fail 'assume clears index bit'

# An actual editor supplies messages for the interactive commit helpers.
print -rl -- '#!/bin/sh' 'printf "Helper commit\n" > "$1"' > "$sandbox/editor"
chmod +x "$sandbox/editor"
export GIT_EDITOR="$sandbox/editor"
commit-all
[[ -z $(command git status --porcelain) ]] || fail 'commit-all stages and commits'
print -r -- upstream >> tracked.txt
upstream
[[ $(command git rev-parse HEAD) == $(command git --git-dir="$sandbox/remote.git" rev-parse main) ]] || fail 'upstream commits and pushes'

branch 'CODE-1234 My Branch!'
[[ $(command git branch --show-current) == code-1234_my_branch_ ]] || fail 'branch normalizes name'
move main
for kind in feature hotfix bugfix release; do
  "$kind" 'Some Work'
  [[ $(command git branch --show-current) == "$kind/some_work" ]] || fail "$kind prefix"
  move main
done

# A clean move must not consume a stash created by the user.
print -r -- saved >> tracked.txt
command git stash push --quiet -m 'User stash'
saved=$(command git rev-parse refs/stash)
move feature/some_work
[[ $(command git rev-parse refs/stash) == $saved ]] || fail 'move preserves existing stash'
move main
command git stash pop --quiet
stage tracked.txt
print -r -- dirty >> 'with spaces.txt'
print -r -- portable > 'portable file.txt'
move feature/some_work
[[ $(command git diff --cached --name-only) == tracked.txt ]] || fail 'move preserves staged changes'
[[ $(tail -n 1 'with spaces.txt') == dirty && -f 'portable file.txt' ]] || fail 'move carries unstaged and untracked changes'
move -n main
[[ -z $(command git status --porcelain) ]] || fail 'move -n leaves changes stashed'
command git stash pop --quiet --index
commit-all

print -r -- remote > remote.txt
stage remote.txt
commit --quiet -m Remote
push origin HEAD:remote-topic
move -un remote-topic
[[ $(command git branch --show-current) == remote-topic ]] || fail 'move fetches remote branch'
[[ $(command git rev-parse --abbrev-ref '@{upstream}') == origin/remote-topic ]] || fail 'move sets remote tracking'
move main
merge remote-topic
[[ -f remote.txt ]] || fail 'merge combines branches'

# A checkout refused by Git must restore changes on the original branch.
command git worktree add --quiet "$sandbox/busy" feature/some_work
print -r -- retry >> tracked.txt
if move feature/some_work > "$sandbox/error" 2>&1; then
  fail 'move must report checkout failure'
fi
grep -Eq 'worktree|checked out' "$sandbox/error" || fail 'checkout failure includes diagnostic'
[[ $(command git branch --show-current) == main && $(tail -n 1 tracked.txt) == retry ]] || fail 'failed checkout restores original work'
command git restore tracked.txt
command git worktree remove "$sandbox/busy"

# A conflicted stash application must leave the saved work recoverable.
branch stash-conflict
print -r -- other > tracked.txt
stage tracked.txt
commit --quiet -m 'Conflicting branch'
move main
print -r -- mine > tracked.txt
if move stash-conflict > "$sandbox/error" 2>&1; then
  fail 'move must report stash conflicts'
fi
[[ -n $(command git ls-files --unmerged) ]] || fail 'move conflict is visible'
command git rev-parse --verify refs/stash > /dev/null || fail 'move conflict retains stash'
grep -q -i conflict "$sandbox/error" || fail 'move conflict includes diagnostic'
# This repository is a disposable fixture; discard only its conflicted checkout.
command git reset --quiet --hard HEAD
command git stash drop --quiet
move main

# Merge controls operate on a real merge conflict.
branch merge-conflict
print -r -- theirs > tracked.txt
stage tracked.txt
commit --quiet -m Theirs
move main
print -r -- ours > tracked.txt
stage tracked.txt
commit --quiet -m Ours
if merge merge-conflict > "$sandbox/error" 2>&1; then
  fail 'merge must report conflicts'
fi
grep -q CONFLICT "$sandbox/error" || fail 'merge conflict includes diagnostic'
merge --abort
[[ -z $(command git ls-files --unmerged) ]] || fail 'merge abort clears conflict'
if merge merge-conflict > "$sandbox/error" 2>&1; then
  fail 'merge must report repeated conflict'
fi
print -r -- resolved > tracked.txt
stage tracked.txt
merge --continue
[[ -z $(command git ls-files --unmerged) ]] || fail 'merge continue finishes resolution'

# Dirty submodules are not stashable and must not make move consume an older stash.
command git -c protocol.file.allow=always submodule add --quiet "$sandbox/remote.git" component
stage .gitmodules component
commit --quiet -m 'Add component'
branch submodule-target
move main
print -r -- saved >> tracked.txt
command git stash push --quiet -m 'User stash before submodule change'
saved=$(command git rev-parse refs/stash)
print -r -- component >> component/tracked.txt
move submodule-target > "$sandbox/submodule-output" 2>&1
remaining=$(command git rev-parse --verify --quiet refs/stash) || fail 'move consumed user stash for submodule-only changes'
[[ $remaining == $saved ]] || fail 'move preserves user stash with dirty submodule'
command git -C component restore tracked.txt
command git stash pop --quiet
commit-all
move main

tag --patch
[[ $(tag --latest) == 0.0.1 ]] || fail 'patch without tags'
tag 2.9.0
tag v1.99.0
tag 2.10.0-rc.1
tag unrelated
[[ $(tag --latest) == 2.9.0 ]] || fail 'latest compares numbers and ignores prereleases'
tag --minor
[[ $(tag --latest) == 2.10.0 ]] || fail 'minor resets patch'
tag --major
[[ $(tag --latest) == 3.0.0 ]] || fail 'major resets minor and patch'
tag v4.2.9
tag -z
[[ $(tag -l) == v4.2.10 ]] || fail 'patch preserves v prefix'
tag -y
tag -x
[[ $(tag -l) == v5.0.0 && $(tag) == *unrelated* ]] || fail 'short tag options and listing'
[[ $(tag --help) == *--major* ]] || fail 'tag help'

# Git's real URL rewriting sends SSH-form clone URLs to a local bare remote.
export GIT_CONFIG_GLOBAL="$sandbox/gitconfig"
command git config --global url."$sandbox/remote.git".insteadOf 'git@github.com:owner/repo.git'
command git config --global --add url."$sandbox/remote.git".insteadOf 'git@bitbucket.org:owner/repo.git'
command git config --global user.github owner
command git config --global user.bitbucket owner
for host in github bitbucket; do
  for form in slash separate configured; do
    mkdir -p "$sandbox/$host/$form"
    cd "$sandbox/$host/$form"
    case $form in
      slash) "$host" owner/repo ;;
      separate) "$host" owner repo ;;
      configured) "$host" repo ;;
    esac
    [[ -d repo/.git ]] || fail "$host clones using $form arguments"
  done
done
cd "$sandbox/work"
if github 'bad owner/repo' > "$sandbox/error" 2>&1; then
  fail 'hosting command must reject malformed names'
fi
grep -q usage "$sandbox/error" || fail 'hosting failure includes usage'
if move nonexistent > "$sandbox/error" 2>&1; then
  fail 'move must reject missing branches'
fi
grep -q nonexistent "$sandbox/error" || fail 'missing branch includes diagnostic'
[[ -z $(command git status --porcelain) ]] || fail 'failed move leaves checkout unchanged'

print -r -- 'Command smoke checks passed.'
