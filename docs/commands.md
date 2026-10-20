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

All four commands preserve Git's exit status. The plugin invokes the Git
executable rather than a shell alias or function named `git`.
