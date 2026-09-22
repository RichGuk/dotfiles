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

# Type this blind after a TUI dies without restoring the terminal. The first
# escape pops the kitty keyboard protocol: until it does, every modified key
# arrives as a literal CSI-u sequence, so ctrl+c prints `^[[99;5u` instead of
# ever becoming a signal.
function unwedge() {
  printf '\033[<u\033[?1049l\033[?1000l\033[?1006l\033[?2004l\033[?25h'
  stty sane
}
