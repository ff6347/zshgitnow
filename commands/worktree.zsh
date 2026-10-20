# ABOUTME: Provides Git inspection, index, and commit workflow commands.
# ABOUTME: Exposes command discovery and preserves Git diagnostics and exit codes.

function gitnow {
  emulate -L zsh
  case ${1-} in
    -v|--version) print -r -- 'zshgitnow 0.1.0' ;;
    ''|-h|--help)
      print -rl -- 'zshgitnow 0.1.0' '' \
        'Git: state stage unstage show untracked commit commit-all tag' \
        '     pull push upstream move merge assume logs' \
        'Branches: branch feature hotfix bugfix release' \
        'Hosting: github bitbucket'
      ;;
    *) print -u2 -- 'usage: gitnow [--help | --version]'; return 2 ;;
  esac
}

function state {
  emulate -L zsh
  command git status --short --branch "$@"
}

function unstage {
  emulate -L zsh
  if (( $# == 0 )); then
    command git reset -- .
  else
    command git reset "$@"
  fi
}

function show {
  emulate -L zsh
  if (( $# == 0 )); then
    set -- --compact-summary HEAD
  fi
  command git show "$@"
}

function untracked {
  emulate -L zsh
  if (( $# )); then
    print -u2 -- 'usage: untracked (dry run only)'
    return 2
  fi
  command git clean --dry-run -d
}

function commit-all {
  emulate -L zsh
  if (( $# )); then
    print -u2 -- 'usage: commit-all'
    return 2
  fi
  stage && commit .
}

function upstream {
  emulate -L zsh
  if (( $# )); then
    print -u2 -- 'usage: upstream'
    return 2
  fi
  commit-all "$@" && push
}

function logs {
  emulate -L zsh
  if (( $# == 0 )); then
    set -- HEAD
  fi
  command git log --graph --decorate --oneline "$@"
}

function assume {
  emulate -L zsh
  local flag=--assume-unchanged
  case ${1-} in
    -h|--help)
      print -r -- 'usage: assume [-n | --no-assume] [--] file…'
      return 0
      ;;
    -n|--no-assume) flag=--no-assume-unchanged; shift ;;
  esac
  if [[ ${1-} == -- ]]; then
    shift
  fi
  if (( $# == 0 )); then
    print -u2 -- 'usage: assume [-n | --no-assume] [--] file…'
    return 2
  fi
  command git update-index "$flag" -- "$@"
}
