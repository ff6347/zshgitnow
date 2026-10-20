# zsh gitnow

Native zsh Git workflow commands inspired by
[GitNow](https://github.com/joseluisq/gitnow).
Requires Git and zsh; Fish and Oh My Zsh are not required.

## Install without Oh My Zsh

Clone the plugin:

```zsh
git clone https://github.com/ff6347/zshgitnow.git "$HOME/.local/share/zshgitnow"
```

Add this line to `~/.zshrc`:

```zsh
source "$HOME/.local/share/zshgitnow/gitnow.plugin.zsh"
```

Open a fresh zsh shell. If you already have a checkout, you can source
`gitnow.plugin.zsh` from that directory instead. Keep the `commands/` directory
beside the plugin file; the plugin loads its helpers from there.

## Install with Oh My Zsh

Clone into the custom plugins directory:

```zsh
git clone https://github.com/ff6347/zshgitnow.git \
  "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/gitnow"
```

Alternatively, symlink an existing checkout to that `plugins/gitnow` path.

Add `gitnow` to your existing plugin list in `~/.zshrc`, before Oh My Zsh loads:

```zsh
plugins=(git gitnow) # Keep your other plugins in this list.
source "$ZSH/oh-my-zsh.sh"
```

Open a fresh zsh shell. Use either installation method, not both.

## Use

Inside a Git repository:

```zsh
stage                      # Stage changes in the current directory and below.
stage "file with spaces"    # Or choose files explicitly.
commit -m "Describe changes"
pull                       # Rebase onto the remote branch, autostashing changes.
push                       # Push and set upstream tracking.
```

Available commands:

| Group | Commands |
| --- | --- |
| Inspection | `gitnow`, `state`, `show`, `untracked`, `logs` |
| Changes | `stage`, `unstage`, `commit`, `commit-all`, `upstream`, `assume` |
| Synchronization | `pull`, `push`, `move`, `merge` |
| Branches | `branch`, `feature`, `hotfix`, `bugfix`, `release` |
| Tags and cloning | `tag`, `github`, `bitbucket` |

See the [command reference](docs/commands.md) for arguments and remote selection.

The plugin defines shell functions with the command names above.
Check for conflicts with `type stage commit pull push`; existing aliases can take
precedence, and should be removed explicitly if you want these functions instead.
The plugin does not change Git configuration, install keybindings, or load
`~/.gitnow`. This is a native implementation of the documented command set,
not a byte-for-byte port of Fish output or configuration. In particular, `move`
also carries untracked files and preserves staging when reapplying its stash.

Bash and other shells can use the executable launchers in `bin/` without
sourcing the plugin. See [Bash and agent setup](docs/bash.md) for PATH setup and
Pi's `!` commands. The launchers reuse the same zsh implementation.

## Smoke check

From this checkout:

```zsh
for file in gitnow.plugin.zsh commands/*.zsh tests/*.zsh; do
  zsh -n "$file" || break
done
zsh tests/smoke.zsh
zsh tests/commands-smoke.zsh
bash tests/bash-smoke.sh
```

The smoke checks use temporary local repositories and a local bare remote.
Hosting clone checks use Git URL rewriting to that remote, rather than live SSH
connections. No network access or personal repository changes are needed.
