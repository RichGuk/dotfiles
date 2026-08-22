setopt prompt_subst

PROMPT='%(?.%F{blue}.%F{red})$(prompt_context)%(?.%F{blue}.%F{red})❯%f '
RPROMPT='%F{248} %50<...<%~ $(git_prompt_info)%f '

prompt_context () {
  if [[ "$USER" != "$DEFAULT_USER" || -n "$SSH_CLIENT" ]]; then
    print -n "%F{005}$USER@%m%f "
  fi
}

# Checks if working tree is dirty
function git_prompt_info() {
  local ref
  ref=$(git symbolic-ref --short HEAD 2> /dev/null) || return

  if [[ -n $(git status --porcelain --ignore-submodules=dirty 2> /dev/null) ]]; then
    echo "%F{red}\ue725 ${ref}%f"
  else
    echo "%F{green}\ue725 ${ref}%f"
  fi
}

function ls_colours() {
  for code in {000..255}; do print -P -- "$code: %F{$code}Test%f"; done
}
