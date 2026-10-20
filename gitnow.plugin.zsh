# ABOUTME: Provides GitNow-style stage, commit, pull, and push commands for zsh.
# ABOUTME: Loads directly from .zshrc or as an Oh My Zsh plugin.

function stage {
  emulate -L zsh
  if (( $# == 0 )); then
    set -- .
  fi
  command git add "$@"
}

function commit {
  emulate -L zsh
  command git commit "$@"
}

function _gitnow_sync {
  emulate -L zsh
  local operation=$1
  shift
  local -a flags
  if [[ $operation == pull ]]; then
    flags=(--rebase --autostash)
  else
    flags=(--set-upstream)
  fi

  # Explicit remote/branch arguments and options are passed through to Git.
  if (( $# > 0 )) && [[ $operation == push || $# -ne 1 || $1 == -* ]]; then
    command git "$operation" "${flags[@]}" "$@"
    return $?
  fi

  local branch remote ref
  branch=$(command git symbolic-ref --quiet --short HEAD) || {
    print -u2 -- "gitnow: cannot infer a branch (outside a repository or detached HEAD); specify a remote and branch."
    return 1
  }
  remote=$(command git config --get "branch.${branch}.remote") || remote=origin
  if (( $# == 1 )); then
    ref=$1
  else
    ref=$(command git config --get "branch.${branch}.merge") || ref="refs/heads/$branch"
    ref=${ref#refs/heads/}
  fi

  if [[ $operation == push ]]; then
    command git push "${flags[@]}" "$remote" "HEAD:refs/heads/$ref"
  else
    command git pull "${flags[@]}" "$remote" "$ref"
  fi
}

function pull {
  _gitnow_sync pull "$@"
}

function push {
  _gitnow_sync push "$@"
}
