<!-- ABOUTME: Stores durable project workflow and shell integration decisions. -->
<!-- ABOUTME: Summarizes the command scope and verification approach. -->

# Project memory

- [decision] gitnow.plugin.zsh supports only stage, commit, pull, and push, and is loadable directly or through Oh My Zsh.
- [preference] Fabian permits work directly on main without PRs and requests smoke checks only, not an extended suite.
- [technique] Run zsh tests/smoke.zsh for real local Git operations, including rebase/autostash and differently named upstream branches.
- [risk] Do not modify personal shell startup files without explicit approval.
