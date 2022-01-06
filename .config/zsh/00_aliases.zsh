alias pu="pushd"
alias po="popd"

alias ...='cd ../..'

alias history='fc -l l'

alias l='ls -la'
alias ll='ls -l'
alias lb='lsblk -o NAME,UUID,FSTYPE,SIZE,TYPE,LABEL,MOUNTPOINT,FSAVAIL,FSUSE%,MODEL,SERIAL'
alias be='bundle exec'
alias ealias="vim ~/.config/zsh/00_aliases.zsh"

alias config='/usr/bin/git --git-dir=$HOME/.dotfiles --work-tree=$HOME'
alias tmux='tmux -f $HOME/.config/tmux/tmux.conf'

alias vim="nvim"
alias vi="nvim"

alias n="notes"


projects=$HOME/Projects
