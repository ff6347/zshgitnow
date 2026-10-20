<!-- ABOUTME: Stores durable project workflow and shell integration decisions. -->
<!-- ABOUTME: Summarizes the command scope and verification approach. -->

# Project memory

- [decision] gitnow.plugin.zsh loads the documented GitNow command set from commands/ modules and works directly or through Oh My Zsh; Fish configuration and keybindings are excluded.
- [preference] Fabian permits work directly on main without PRs and requests smoke checks only, not an extended suite.
- [technique] Run zsh tests/smoke.zsh and zsh tests/commands-smoke.zsh for local Git operations; hosting URLs are checked with real clones and Git URL rewriting.
- [lesson] Brace zsh variables before literal refspec colons: ${target}:refs avoids interpreting :r as a parameter modifier.
- [decision] move owns its stash, includes untracked files, restores the index, and keeps saved changes recoverable on checkout or application failure.
- [lesson] Nonempty git status does not guarantee stash push created a stash (dirty submodules); compare refs/stash before and after before restoring anything.
- [risk] Do not modify personal shell startup files without explicit approval.
