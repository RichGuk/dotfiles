setopt prompt_subst
setopt auto_name_dirs

PROMPT='%(?.%F{blue}.%F{red})$(prompt_context)%(?.%F{blue}.%F{red})❯%{$reset_color%} %f'
RPROMPT='%{$reset_color%}%F{248} %50<...<%~ $(git_prompt_info)%{$reset_color%} '

prompt_context () {
  if [[ "$USER" != "$DEFAULT_USER" || -n "$SSH_CLIENT" ]]; then
    echo -n "%{$reset_color%}%F{005}$USER@%m%{$reset_color%} "
  fi
}

# Checks if working tree is dirty
function git_prompt_info() {
  ref=$(git symbolic-ref HEAD 2> /dev/null) || return

  if [[ -n $(git status -s 2> /dev/null) ]]; then
    echo "%F{red}\ue725 ${ref#refs/heads/}%{$reset_color%}"
  else
    echo "%F{green}\ue725 ${ref#refs/heads/}%{$reset_color%}"
  fi
}

function ls_colours() {
  for code in {000..255}; do print -P -- "$code: %F{$code}Test%f"; done
}
