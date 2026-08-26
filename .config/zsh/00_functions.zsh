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

# Wraps ~/Scripts/refresh-agent so the export lands in the current shell.
function refresh-agent() {
  local assignment
  assignment=$(command refresh-agent --export) || return 1
  eval "$assignment"
  echo "SSH_AUTH_SOCK -> $SSH_AUTH_SOCK"
}
