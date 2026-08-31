alias pu="pushd"
alias po="popd"

# alias history='fc -l l'

alias ls='eza --icons=always'
alias ll='eza -al --icons=always'
alias lt='eza -a --tree --level=1 --icons=always'

alias lb='lsblk -o NAME,UUID,FSTYPE,SIZE,TYPE,LABEL,MOUNTPOINT,FSAVAIL,FSUSE%,MODEL,SERIAL'
alias be='bundle exec'
alias ealias="vim ~/.config/zsh/00_aliases.zsh"

alias dots='/usr/bin/git --git-dir=$HOME/.dotfiles --work-tree=$HOME'

alias vim='nvim'
alias vi='nvim'

# Separate herdr servers so work and personal project lists stay apart.
# herdr-sessionizer scopes its picker to match HERDR_SESSION.
alias hw='herdr --session work'
alias hp='herdr --session personal'
alias hwr='herdr --remote atlantis.work --session work'
