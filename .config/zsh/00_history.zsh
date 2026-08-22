[ -d $HOME/.cache/zsh ] || mkdir -p $HOME/.cache/zsh
HISTFILE=$HOME/.cache/zsh/history
HISTSIZE=100000
SAVEHIST=100000

setopt hist_ignore_dups
setopt share_history # implies inc_append_history

setopt hist_verify
setopt extended_history
setopt hist_expire_dups_first
setopt hist_ignore_space
setopt hist_reduce_blanks
