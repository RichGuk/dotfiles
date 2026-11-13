bindkey -v
KEYTIMEOUT=1 # default 40 puts a 0.4s stall after every Escape

bindkey "^A" beginning-of-line # Ctrl + a
bindkey "^E" end-of-line # Ctrl + e

bindkey '^[[A' up-line-or-search # Up
bindkey '^[[B' down-line-or-search # Down
bindkey '^r' history-incremental-search-backward # Search history backwards with Ctrl + r
bindkey "^[[Z" reverse-menu-complete # Shift + Tab
bindkey ' ' magic-space

# A widget rather than `bindkey -s`, which types the string onto whatever is
# already on the line. push-line stashes any half-written command and restores
# it at the next prompt.
tmux-sessionizer-widget() {
  zle push-line
  BUFFER='tmux-sessionizer'
  zle accept-line
}
zle -N tmux-sessionizer-widget
bindkey '^f' tmux-sessionizer-widget
