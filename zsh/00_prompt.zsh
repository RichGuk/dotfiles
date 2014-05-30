setopt prompt_subst
setopt auto_name_dirs

PROMPT='${SSH_TTY:+[%n@%m] }%F{071}${PWD/#$HOME/~}> %f'
RPROMPT='%{$reset_color%}$(git_prompt_info)%{$reset_color%} '

function ls_colours() {
  for code in {000..255}; do print -P -- "$code: %F{$code}Test%f"; done
}

ZSH_THEME_GIT_PROMPT_PREFIX="%F{226} "
ZSH_THEME_GIT_PROMPT_SUFFIX="%f"
ZSH_THEME_GIT_PROMPT_DIRTY="⚡ "
ZSH_THEME_GIT_PROMPT_CLEAN=""
