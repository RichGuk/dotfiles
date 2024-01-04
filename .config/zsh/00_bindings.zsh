# Enable vi bindings, however I'm still used to a lot of emacs style ctrl this,
# ctrl that so set them up too.
bindkey -v

bindkey "^[[H" beginning-of-line # Home
bindkey "^[[1~" end-of-line # End
bindkey "^[[F"  end-of-line  # End
bindkey "^[[4~" end-of-line # End
bindkey "^A" beginning-of-line
bindkey "^E" end-of-line
bindkey "^[^[[C" forward-word # Ctrl + Right
bindkey "^[^[[D" backward-word # Ctrl + Left

# Make it so after a partial type of word pressing up and down searches history
# for that word, i.e. git and up shows all git history - love this.
bindkey '^[[A' up-line-or-search # Up
bindkey '^[[B' down-line-or-search # Down
bindkey '^r' history-incremental-search-backward # Search history backwards with Ctrl + r
bindkey "^[[Z" reverse-menu-complete # Shift + Tab
bindkey ' ' magic-space

# Make the delete key (or Fn + Delete on the Mac) work instead of outputting a ~
bindkey '^?' backward-delete-char # Delete
bindkey "^[[3~" delete-char  # Delete
bindkey "^[3;5~" delete-char # Fn + Delete
bindkey "\e[3~" delete-char # Delete

bindkey -s ^f "tmux-sessionizer\n"
