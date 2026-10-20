<!-- ABOUTME: Documents arguments and defaults for the zsh GitNow commands. -->
<!-- ABOUTME: Describes remote selection and Git safety considerations. -->

# Command reference

## `stage [arguments…]`

Runs `git add .` when called without arguments, staging additions, modifications,
and deletions in the current directory and its descendants. With arguments,
runs `git add` with exactly those arguments.

```zsh
stage
stage -- "file with spaces.txt"
stage -p
```

## `commit [arguments…]`

Runs `git commit` with exactly the supplied arguments. With no arguments, Git
opens the configured editor. Git hooks run normally.

## `pull [branch | remote branch | Git arguments…]`

Runs `git pull --rebase --autostash`.

- No arguments: uses the current branch's configured tracking remote and branch.
  Without tracking configuration, defaults to `origin` and the current branch.
- One non-option argument: treats it as a branch on the inferred remote.
- Multiple arguments, or a single option: passes them through to Git, which
  applies its own remote-selection rules.

```zsh
pull
pull main
pull origin main --verbose
```

Autostash saves and reapplies tracked working changes; it does not stash
untracked files. Rebase or stash application can conflict and require manual
resolution. Explicit Git options can override the default flags.

## `push [Git arguments…]`

Runs `git push --set-upstream`.

- No arguments: pushes `HEAD` to the configured tracking remote branch, or to
  `origin` under the current branch name if no tracking configuration exists.
- With arguments: passes them through to Git unchanged.

```zsh
push
push origin main
```

No force option is added. Inferred operations require an attached branch;
from detached HEAD, supply explicit arguments such as `push origin HEAD:topic`.

Git failures and usage errors return a nonzero status. The plugin invokes the
Git executable rather than a shell alias or function named `git`.

## Inspection

| Command | Behavior |
| --- | --- |
| `gitnow` | Prints the plugin version and available commands |
| `gitnow --version` / `-v` | Prints the native plugin version |
| `gitnow --help` / `-h` | Prints the version and command list |
| `state [arguments…]` | Runs `git status --short --branch` with additional arguments |
| `show [arguments…]` | Defaults to `git show --compact-summary HEAD`; explicit arguments replace those defaults |
| `untracked` | Runs `git clean --dry-run -d`; never deletes anything and accepts no arguments |
| `logs [arguments…]` | Runs `git log --graph --decorate --oneline`; defaults to `HEAD` |

## `unstage [arguments…]`

With no arguments, runs `git reset -- .`, unstaging changes in the current
directory and below without discarding working files. Explicit arguments are
passed to `git reset` unchanged; options such as `--hard` retain their normal
Git meaning and can discard changes.

## `commit-all` and `upstream`

`commit-all` runs `stage` followed by `commit .`, opening the configured commit
editor. Its scope is the current directory and below, not necessarily the entire
repository. It accepts no arguments.

`upstream` runs `commit-all` and then `push`. A failed stage or commit stops the
sequence, so nothing is pushed. It accepts no arguments.

## `assume [-n | --no-assume] [--] file…`

Runs `git update-index --assume-unchanged` for the specified tracked files.
`-n` or `--no-assume` clears that bit with `--no-assume-unchanged`.
`-h` or `--help` prints usage.

This is an index optimization hint, not an ignore rule or protection against
Git overwriting files. It does not change `.gitignore`.

## Branch creation

Each command accepts one branch name, lowercases it, replaces characters outside
ASCII letters, digits, underscores, and hyphens with underscores, then creates
and checks out the branch. Quote names containing spaces. Git validates the
resulting branch name and rejects existing branches.

| Command | Result for `"Some Work"` |
| --- | --- |
| `branch` | `some_work` |
| `feature` | `feature/some_work` |
| `hotfix` | `hotfix/some_work` |
| `bugfix` | `bugfix/some_work` |
| `release` | `release/some_work` |

## `move [-u] [-n] branch`

Moves to an existing local branch while carrying staged, unstaged, and untracked
changes through a stash. Ignored files and changes inside submodule working
trees are not stashed. Existing stashes are left untouched when no new stash is
created.

- `-u` / `--upstream`: fetches the named branch from `origin`; creates a tracking
  local branch if it does not exist, otherwise switches to the existing branch.
  Fetching does not reset an existing local branch to the remote tip.
- `-n` / `--no-apply-stash`: leaves saved changes in the stash instead of applying
  them after checkout.
- `-un` / `-nu`: combines both options.

If checkout fails, saved changes are reapplied on the original branch. If stash
application conflicts, `move` returns a failure and retains the stash; resolve
conflicts and verify your files before dropping it. Successful application
restores staging and removes only the stash created by that move when it is
still the top stash.

```zsh
move feature/some_work
move -u remote-topic
move -n main
```

## `merge branch | --abort | --continue`

Merges an existing local branch into the current branch with `git merge`.
`-a` / `--abort` aborts a conflicted merge; `-c` / `--continue` continues after
you resolve conflicts and stage the resolutions. Git's editor and hooks run
normally. No branch is deleted.

## `tag [name | option]`

With no arguments, lists all tags using Git's version ordering. With a custom
name, creates a lightweight tag at `HEAD`. Supported options:

| Option | Behavior |
| --- | --- |
| `-x` / `--major` | Increments major and resets minor and patch to zero |
| `-y` / `--minor` | Increments minor and resets patch to zero |
| `-z` / `--patch` | Increments patch |
| `-l` / `--latest` | Prints the highest stable semantic-version tag, or nothing if none exists |
| `-h` / `--help` | Prints usage |

Automatic increments select the highest numeric `MAJOR.MINOR.PATCH` tag,
optionally prefixed with `v`. They ignore prerelease, build-metadata, and other
tag names, and preserve the selected tag's prefix. Without a matching tag,
start from `0.0.0`: `--major` creates `1.0.0`, `--minor` creates `0.1.0`, and
`--patch` creates `0.0.1`. Tags are local; nothing is pushed automatically.

## `github` and `bitbucket`

Clone repositories using SSH. Both accept these forms:

```zsh
github owner/repo
github owner repo
github repo           # Reads owner from Git configuration: user.github
bitbucket owner/repo
bitbucket owner repo
bitbucket repo        # Reads owner from Git configuration: user.bitbucket
```

An optional `.git` suffix is accepted. SSH access to the hosting service is
required. The destination directory is chosen by `git clone` from the repository
name. The helpers do not create hosted repositories or change Git configuration.
