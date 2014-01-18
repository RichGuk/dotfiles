alias pu="pushd"
alias po="popd"

alias ...='cd ../..'

alias history='fc -l l'

alias l='ls -la'
alias ll='ls -l'

alias be='bundle exec'
alias rspec='nocorrect rspec'
alias vim='nocorrect vim'

# Foreman for apps.
alias fr_dev='bundle exec foreman run -e .env_development'
alias fr_prod='bundle exec foreman run -e .env_production'
alias fr_staging='bundle exec foreman run -e .env_staging'
alias fr_test='bundle exec foreman run -e .env_test'
alias fr=fr_dev

alias -g with_tmux=' -t tmux a'

alias todo='~/Scripts/todo.txt-cli/todo.sh -d ~/.todo.cfg'

alias ealias="vim ${DOTFILES}/zsh/aliases.zsh"

alias z='zeus'
alias zdb='zeus rake db:migrate'
alias zm='zeus g model'

projects=$HOME/Projects
