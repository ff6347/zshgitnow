<!-- ABOUTME: Records implementation decisions and verification for the shell commands. -->
<!-- ABOUTME: Captures project scope and operator-approved workflow choices. -->

# Shell commands

- [decision] Implement stage, commit, pull, and push as one sourceable zsh plugin; Oh My Zsh loads the same file.
- [decision] Base command behavior on GitNow's published README, without copying Fish implementation code.
- [decision] Inferred sync operations use Git tracking configuration and fall back to origin/current branch; explicit arguments pass through.
- [preference] Fabian authorized direct work on main, no pull requests, and smoke checks rather than an extended test suite.
- [technique] Reproduce missing functionality with the smoke script before creating the plugin; verify using temporary working repositories and a bare local remote.
- [risk] Autostash excludes untracked files and may conflict on application; existing shell aliases may shadow the plugin functions.
- [decision] Shell startup files remain untouched; installation instructions cover plain zsh and Oh My Zsh.
- [verification] Smoke checks passed for real Git operations, failure propagation, and detached HEAD diagnostics; zsh syntax checks and ShellCheck's Bash-mode analysis of the plugin passed.
- [verification] Loading the plugin twice with pre-existing command aliases parses successfully; aliases remain under user control.

## Complete command set

- [decision] Fabian approved all remaining commands with direct main commits and smoke checks; configuration and keybindings stay out of scope.
- [decision] Group helper functions under commands/ by worktree operations, branches, tags, and hosting to keep individual source files small.
- [decision] move includes untracked files and restores staging; stash application conflicts retain the stash and failed checkouts restore work on the original branch.
- [lesson] An unbraced variable followed by :refs triggers zsh's :r parameter modifier; brace variables in fetch refspecs.
- [lesson] Generate the smoke editor using print -rl so the shebang and command occupy separate lines.
- [verification] The command smoke check failed on missing gitnow before implementation, then passed with branch, stash, merge conflict, semantic-tag, and local hosting-clone checks.
- [technique] SSH-form clone URLs are exercised using Git's insteadOf rewriting to a local bare remote; live hosting authentication is not tested.
- [lesson] Dirty submodules can make status nonempty while stash push creates no stash. Compare refs/stash before and after saving so move never applies or drops a user's pre-existing stash. A real submodule smoke reproduction failed before this ownership check.

## Executable launchers

- [decision] Fabian approved executable launchers and installation documentation without personal shell configuration changes.
- [decision] bin/gitnow execs zsh -f and dispatches to the existing plugin by invocation name; relative sibling symlinks expose the other command names.
- [technique] Resolve the original invocation name before resolving the launcher path, so chained external symlinks retain their command identity while locating the checkout.
- [verification] The Bash smoke check first failed because the launcher was absent, then passed using non-interactive Bash, literal shell metacharacters, a checkout path with spaces, local sync operations, and exact Git failure status/output comparisons.
- [decision] Document inherited PATH and Pi's shellCommandPrefix instead of sourcing interactive configuration in agent commands.

## Local installation

- [decision] Fabian approved installing launcher symlinks in ~/.local/bin, which is already present on the current agent's inherited PATH.
- [verification] Checked all 23 destination names for collisions before installation; none existed and no files were overwritten.
- [verification] All installed commands resolve through ~/.local/bin from bash --noprofile --norc without altering PATH. gitnow --version and state also ran directly through the agent shell tool.
- [risk] Installed links target this checkout's bin/ directory; keep the checkout in place. Shell startup files and Pi settings were not modified.
