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

# Only when nothing usable is set already: inside an SSH session sshd has
# pointed it at the forwarded agent, and overriding that would use this
# machine's keys instead of the ones from the far end. A live forwarded socket
# passes -S, so widening the test from "unset" to "not a socket" cannot steal
# one -- it only catches a value inherited from a dead connection, which is
# otherwise carried for the whole life of the shell.
#
# This is the only place SSH_AUTH_SOCK is decided -- there is no precmd hook
# revising it later, so the value has to be right on its own. It is, because
# the socket is systemd-activated: the path always exists and connecting starts
# the agent, so it needs no liveness check of its own. `-S` above is only there
# to spot an inherited value that is NOT that socket and has since died.
#
# This file is also what uwsm's env preloader reads at login, so a wrong value
# here becomes the whole graphical session's SSH_AUTH_SOCK.
if [[ "$OSTYPE" != darwin* && ! -S "$SSH_AUTH_SOCK" ]]; then
  export SSH_AUTH_SOCK="${XDG_RUNTIME_DIR:-/run/user/$UID}/ssh-agent.socket"
fi
