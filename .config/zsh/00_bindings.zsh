# Enable vi bindings, however I'm still used to a lot of emacs style ctrl this,
# ctrl that so set them up too.
bindkey -v

bindkey "^[[H" beginning-of-line
bindkey "^[[1~" end-of-line
bindkey "^A" beginning-of-line
bindkey "^[[F"  end-of-line
bindkey "^[[4~" end-of-line
bindkey "^E" end-of-line
bindkey "^[^[[C" forward-word
bindkey "^[^[[D" backward-word

# Make it so after a partial type of word pressing up and down searches history
# for that word, i.e. git and up shows all git history - love this.
bindkey '^[[A' up-line-or-search
bindkey '^[[B' down-line-or-search
bindkey '^r' history-incremental-search-backward
bindkey "^[[Z" reverse-menu-complete
bindkey ' ' magic-space

# Make the delete key (or Fn + Delete on the Mac) work instead of outputting a ~
bindkey '^?' backward-delete-char
bindkey "^[[3~" delete-char
bindkey "^[3;5~" delete-char
bindkey "\e[3~" delete-char

bindkey -s ^f "tmux-sessionizer\n"
