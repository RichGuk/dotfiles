bindkey -v

bindkey "^A" beginning-of-line # Ctrl + a
bindkey "^E" end-of-line # Ctrl + e

bindkey '^[[A' up-line-or-search # Up
bindkey '^[[B' down-line-or-search # Down
bindkey '^r' history-incremental-search-backward # Search history backwards with Ctrl + r
bindkey "^[[Z" reverse-menu-complete # Shift + Tab
bindkey ' ' magic-space

bindkey -s ^f "tmux-sessionizer\n"
