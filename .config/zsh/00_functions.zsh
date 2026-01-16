# No arguments: `git status`
# With arguments: acts like `git`
g() {
  if [[ $# > 0 ]]; then
    git $@
  else
    git status
  fi
}
# Complete g like git
compdef g=git

function mcd() {
  mkdir -p "$1" && cd "$1";
}

function brew() {
  command brew "$@"

  if [[ $* =~ "upgrade" ]] || [[ $* =~ "update" ]] || [[ $* =~ "outdated" ]]; then
    sketchybar --trigger brew_update
  fi
}

function refresh-agent() {
  # Ensure zsh doesn't error if no matches
  setopt local_options no_nomatch 2>/dev/null

  for sock in /tmp/ssh-*/agent.* /run/user/$UID/ssh-*/agent.*; do
    # Skip literal patterns (means: no match happened)
    case "$sock" in
      *\**|"" ) continue ;;
    esac

    if SSH_AUTH_SOCK="$sock" ssh-add -l >/dev/null 2>&1; then
      export SSH_AUTH_SOCK="$sock"
      echo "SSH_AUTH_SOCK -> $SSH_AUTH_SOCK"
      return 0
    fi
  done

  echo "No valid SSH agent socket found." >&2
  return 1
}
