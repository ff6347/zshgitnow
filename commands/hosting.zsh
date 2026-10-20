# ABOUTME: Clones GitHub and Bitbucket repositories using SSH URLs.
# ABOUTME: Resolves owner names from arguments or the user's Git configuration.

function _gitnow_clone {
  emulate -L zsh
  local service=$1 host=$2
  shift 2
  local repository owner
  case $# in
    1)
      repository=$1
      if [[ $repository != */* ]]; then
        owner=$(command git config --get "user.$service") || {
          print -u2 -- "gitnow: set user.$service in Git configuration or supply owner/repo."
          return 2
        }
        repository="$owner/$repository"
      fi
      ;;
    2) repository="$1/$2" ;;
    *) print -u2 -- "usage: $service owner/repo | owner repo | repo"; return 2 ;;
  esac
  repository=${repository%.git}
  local pattern='^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$'
  if [[ ! $repository =~ $pattern ]]; then
    print -u2 -- "usage: $service owner/repo | owner repo | repo"
    return 2
  fi
  command git clone -- "git@${host}:${repository}.git"
}

function github {
  _gitnow_clone github github.com "$@"
}

function bitbucket {
  _gitnow_clone bitbucket bitbucket.org "$@"
}
