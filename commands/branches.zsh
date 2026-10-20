# ABOUTME: Creates normalized branches and manages branch moves and merges.
# ABOUTME: Preserves staged and working changes through explicitly owned stashes.

function _gitnow_branch {
  emulate -L zsh
  local prefix=$1
  shift
  if (( $# != 1 )) || [[ -z $1 ]]; then
    print -u2 -- 'usage: branch|feature|hotfix|bugfix|release "branch name"'
    return 2
  fi
  local name
  name=$(print -rn -- "${(L)1}" | LC_ALL=C tr -c 'a-z0-9_-' '_') || return $?
  name="$prefix$name"
  command git check-ref-format --branch "$name" > /dev/null || return $?
  command git checkout -b "$name"
}

function branch { _gitnow_branch '' "$@"; }
function feature { _gitnow_branch feature/ "$@"; }
function hotfix { _gitnow_branch hotfix/ "$@"; }
function bugfix { _gitnow_branch bugfix/ "$@"; }
function release { _gitnow_branch release/ "$@"; }

function _gitnow_restore_stash {
  emulate -L zsh
  local saved=$1 current
  command git stash apply --index "$saved" || {
    print -u2 -- "gitnow: saved changes remain in stash $saved; resolve the conflict before dropping it."
    return 1
  }
  current=$(command git rev-parse --verify --quiet refs/stash) || return $?
  if [[ $current == "$saved" ]]; then
    command git stash drop 'stash@{0}'
  else
    print -u2 -- "gitnow: restored changes; retained stash $saved because another stash is on top."
  fi
}

function move {
  emulate -L zsh
  local -i fetch=0 apply=1 result
  while (( $# )); do
    case $1 in
      -u|--upstream) fetch=1; shift ;;
      -n|--no-apply-stash) apply=0; shift ;;
      -un|-nu) fetch=1; apply=0; shift ;;
      --) shift; break ;;
      -*) print -u2 -- "gitnow: unknown move option: $1"; return 2 ;;
      *) break ;;
    esac
  done
  if (( $# != 1 )); then
    print -u2 -- 'usage: move [-u | --upstream] [-n | --no-apply-stash] branch'
    return 2
  fi
  local target=$1 saved='' dirty previous current
  local -a checkout
  command git check-ref-format --branch "$target" > /dev/null || return $?
  if (( fetch )); then
    command git fetch origin "refs/heads/${target}:refs/remotes/origin/$target" || return $?
  fi
  if command git show-ref --verify --quiet "refs/heads/$target"; then
    checkout=("$target")
  elif (( fetch )); then
    checkout=(--track -b "$target" "origin/$target")
  else
    print -u2 -- "gitnow: local branch not found: $target"
    return 1
  fi

  dirty=$(command git status --porcelain) || return $?
  if [[ -n $dirty ]]; then
    previous=$(command git rev-parse --verify --quiet refs/stash) || previous=''
    command git stash push --include-untracked -m "gitnow move to $target" || return $?
    current=$(command git rev-parse --verify --quiet refs/stash) || current=''
    if [[ $current != "$previous" ]]; then
      saved=$current
    fi
  fi
  if command git checkout "${checkout[@]}"; then
    if (( apply )) && [[ -n $saved ]]; then
      _gitnow_restore_stash "$saved"
    fi
  else
    result=$?
    if [[ -n $saved ]]; then
      _gitnow_restore_stash "$saved" || return $?
    fi
    return $result
  fi
}

function merge {
  emulate -L zsh
  if (( $# != 1 )); then
    print -u2 -- 'usage: merge branch | --abort | --continue'
    return 2
  fi
  case $1 in
    -a|--abort) command git merge --abort ;;
    -c|--continue) command git merge --continue ;;
    *)
      command git show-ref --verify --quiet "refs/heads/$1" || {
        print -u2 -- "gitnow: local branch not found: $1"
        return 1
      }
      command git merge "$1"
      ;;
  esac
}
