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

# Only when nothing has set it already: inside an SSH session sshd has pointed
# it at the forwarded agent, and overriding that would use this machine's keys
# instead of the ones from the far end.
#
# $XDG_RUNTIME_DIR rather than ~/.ssh/agent.sock because that path is on disk,
# so the socket file outlives the agent across a reboot -- and `-S` tests that
# a path is a socket, not that anything is listening. This file is also what
# uwsm's env preloader reads at login, so a wrong value here becomes the whole
# session's SSH_AUTH_SOCK.
if [[ "$OSTYPE" != darwin* && -z "$SSH_AUTH_SOCK" ]]; then
  export SSH_AUTH_SOCK="${XDG_RUNTIME_DIR:-/run/user/$UID}/ssh-agent.socket"
fi
