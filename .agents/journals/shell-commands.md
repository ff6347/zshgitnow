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
