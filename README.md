# zsh gitnow

A native zsh implementation of the `stage`, `commit`, `pull`, and `push`
commands inspired by [GitNow](https://github.com/joseluisq/gitnow).
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
`gitnow.plugin.zsh` from that directory instead.

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

See the [command reference](docs/commands.md) for arguments and remote selection.

The plugin defines shell functions named `stage`, `commit`, `pull`, and `push`.
Check for conflicts with `type stage commit pull push`; existing aliases can take
precedence, and should be removed explicitly if you want these functions instead.
The plugin does not change Git configuration, install keybindings, or load
`~/.gitnow`. Other upstream GitNow commands are not implemented.

Bash sessions do not load this zsh plugin. Agents using Bash can continue to use
Git directly, or explicitly run zsh and source the plugin.

## Smoke check

From this checkout:

```zsh
zsh -n gitnow.plugin.zsh
zsh -n tests/smoke.zsh
zsh tests/smoke.zsh
```

The smoke check uses temporary local repositories and a local bare remote;
no network access or personal repository changes are needed.
