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

notes() {
  local notes_dir=${NOTES_DIR:-~/Documents/Notes}

  case "$1" in
    d)
      cd "$notes_dir"
      ;;
    s)
      pushd $notes_dir > /dev/null
      nvim -c "Ag $2"
      popd > /dev/null
      ;;
    f)
      nvim `find $notes_dir -type f -name \*.md  | fzf --preview="cat {}" --preview-window=right:70%:wrap`
      ;;
    p)
      local file=`find $notes_dir -type f -name \*.md | fzf --preview="cat {}" --preview-window=right:70%:wrap`
      output="$notes_dir/pdfs/$(basename "$file" .md).pdf"
      pandoc $file --pdf-engine=xelatex -o "$output"
      echo "$output"
      ;;
    j)
      local file="$notes_dir/Journal/journal-$(date +%Y-%m-%d).md"
      if [ ! -f $file ]; then
        echo "# Journal for $(date +%Y-%m-%d)" > $file
      fi

      nvim -c "norm Go" \
        -c "norm Go## $(date +%H:%M)" \
        -c "norm G2o" \
        -c "norm zz" \
        -c "startinsert" $file
      ;;
    *)
      pushd $notes_dir > /dev/null
      local file="${1:-index}"
      nvim "$notes_dir/$file.md"
      popd > /dev/null
  esac
}
