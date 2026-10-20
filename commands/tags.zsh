# ABOUTME: Lists tags and creates custom or incremented semantic-version tags.
# ABOUTME: Selects stable three-component versions with an optional v prefix.

function tag {
  emulate -L zsh
  if (( $# == 0 )); then
    command git tag --list --sort=version:refname
    return $?
  fi
  if (( $# != 1 )); then
    print -u2 -- 'usage: tag [name | --major | --minor | --patch | --latest | --help]'
    return 2
  fi
  case $1 in
    -h|--help)
      print -rl -- 'usage: tag [name | option]' \
        '-x --major   Increment major, reset minor and patch' \
        '-y --minor   Increment minor, reset patch' \
        '-z --patch   Increment patch' \
        '-l --latest  Print the highest stable semantic version' \
        '-h --help    Show help'
      return 0
      ;;
    -x|--major|-y|--minor|-z|--patch|-l|--latest) ;;
    -*) print -u2 -- "gitnow: unknown tag option: $1"; return 2 ;;
    *) command git tag -- "$1"; return $? ;;
  esac

  local tags candidate latest='' prefix=''
  local -a match
  # zsh populates capture positions when matching a regular expression.
  # shellcheck disable=SC2034
  local -a mbegin mend
  local pattern='^(v?)(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)$'
  local -i major=0 minor=0 patch=0 a b c
  tags=$(command git tag --list) || return $?
  while IFS= read -r candidate; do
    if [[ $candidate =~ $pattern ]]; then
      a=${match[2]} b=${match[3]} c=${match[4]}
      if [[ -z $latest ]] || (( a > major || (a == major && b > minor) || (a == major && b == minor && c > patch) )); then
        latest=$candidate prefix=${match[1]}
        major=$a minor=$b patch=$c
      fi
    fi
  done <<< "$tags"
  case $1 in
    -l|--latest)
      if [[ -n $latest ]]; then
        print -r -- "$latest"
      fi
      return 0
      ;;
    -x|--major) major=$((major + 1)); minor=0; patch=0 ;;
    -y|--minor) minor=$((minor + 1)); patch=0 ;;
    -z|--patch) patch=$((patch + 1)) ;;
  esac
  command git tag -- "${prefix}${major}.${minor}.${patch}"
}
