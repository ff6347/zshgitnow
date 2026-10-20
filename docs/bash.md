<!-- ABOUTME: Explains how to expose GitNow commands to Bash and agent shells. -->
<!-- ABOUTME: Documents PATH setup without loading interactive shell configuration. -->

# Use GitNow from Bash and agent shells

The executable commands in `bin/` run the existing implementation through zsh.
They work from Bash and other shells without sourcing the zsh plugin. Git and
zsh must be installed; Oh My Zsh is not required.

## Put the launchers on PATH

After cloning the repository, add its `bin/` directory to `PATH`. For the clone
location used in the [installation instructions](../README.md):

```bash
export PATH="$HOME/.local/share/zshgitnow/bin:$PATH"
```

For the checkout on this machine, use this instead:

```bash
export PATH="$HOME/Documents/zshgitnow/bin:$PATH"
```

To persist this, add the appropriate export to the startup file used by your
terminal. Interactive Bash typically reads `~/.bashrc`; login Bash reads
`~/.bash_profile` (or another login profile). A zsh terminal can export it from
`~/.zshrc` so processes launched there inherit the same PATH.

The project does not edit those files. Do not source `gitnow.plugin.zsh` from
Bash or source interactive startup files from every agent command.

Verify from a fresh non-interactive Bash:

```bash
bash --noprofile --norc -c 'command -v push; gitnow --version'
```

All commands in the [reference](commands.md) are executable by their own names:

```bash
stage -- "file with spaces.txt"
commit -m "Describe changes"
pull
push
```

`gitnow` lists the commands; it is not a subcommand dispatcher. Use `push`, not
`gitnow push`.

Adding `bin/` first on PATH gives these generic command names priority over
other executables. Existing aliases and functions can still take precedence;
check with `type -a push stage commit`. Keep the complete checkout in place:
launchers need `gitnow.plugin.zsh` and `commands/`. Symlinks to the launchers
are supported; copying individual launchers elsewhere is not.

## Use Pi's `!` commands and Bash tool

Pi's built-in Bash tool and user-entered `!` / `!!` commands use separate
non-interactive shell processes. They inherit PATH from Pi, rather than loading
`~/.bashrc` for each command.

Start Pi from a terminal after exporting PATH as above. For a single launch
without changing startup files:

```bash
PATH="$HOME/Documents/zshgitnow/bin:$PATH" pi
```

Then use:

```text
!gitnow
!state
!pull
!push
```

The model's built-in Bash tool can invoke the same executable names.

For an already running Pi session, alternatively merge this setting into
`~/.pi/agent/settings.json` and run `/reload`:

```json
{
  "shellCommandPrefix": "export PATH=\"$HOME/Documents/zshgitnow/bin:$PATH\""
}
```

If a command prefix already exists, retain its setup and add the PATH export
rather than replacing it. Each command gets a fresh shell: running a standalone
`!export PATH=…` does not configure later commands.

Extensions that replace Pi's shell tool may have their own environment setup.
See Pi's [shell configuration documentation](https://github.com/earendil-works/pi/blob/main/packages/coding-agent/docs/shell-aliases.md)
for its built-in behavior. Other agents work the same way when they inherit
PATH and execute external commands.

## Verify the launchers

From the checkout:

```bash
bash tests/bash-smoke.sh
```

This uses non-interactive Bash, temporary local repositories, and a bare remote.
It checks staging, commits, pulls, pushes, literal arguments, symlinks, and
failure propagation without changing personal repositories or configuration.
