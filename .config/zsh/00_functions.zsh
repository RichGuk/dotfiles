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
