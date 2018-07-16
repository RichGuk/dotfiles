alias pu="pushd"
alias po="popd"

alias ...='cd ../..'

alias history='fc -l l'

alias l='ls -la'
alias ll='ls -l'
alias lb='lsblk -o NAME,FSTYPE,SIZE,TYPE,LABEL,UUID,MOUNTPOINT'

alias be='bundle exec'

alias -g with_tmux=' -t tmux a'

alias todo='~/Scripts/todo.txt-cli/todo.sh -d ~/.todo.cfg'

alias ealias="vim ${DOTFILES}/zsh/aliases.zsh"

alias delmerged='git branch --merged | grep -v "\*" | grep -v master | xargs -n 1 git branch -d'

alias _cp="rsync -aP"

projects=$HOME/Projects
