export ZDOTDIR=${ZDOTDIR:=${HOME}/.config/zsh}

# ~/.local/bin is also added in zshrc, but that only covers *interactive*
# shells. `ssh host <command>` runs zsh non-interactively, which sources this
# file and not zshrc — and `herdr --remote` reaches the server exactly that way,
# so the binary has to be findable here too. typeset -U keeps it deduped when
# zshrc rebuilds $path later.
typeset -U path
path=($HOME/.local/bin $path)
export PATH

export LANG=${LANG:-en_GB.UTF-8}

if [[ "$OSTYPE" != darwin* && -S "$HOME/.ssh/agent.sock" ]]; then
  export SSH_AUTH_SOCK="$HOME/.ssh/agent.sock"
fi
