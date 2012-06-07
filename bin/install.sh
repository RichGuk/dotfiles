#!/bin/bash

BIN_DIR=$(cd "$(dirname "$0")"; pwd)
DOTFILES_DIR=$(dirname "$BIN_DIR")

symlinks=$(find $DOTFILES_DIR -name '*.symlink' -print)
for symlink in $symlinks; do
  name=$(basename "${symlink%.symlink}")
  # Anything beginning with _ should be renamed to .file (e.g. _vimrc -> .vimrc)
  name=${name/#_/.}
  basedir=$(dirname "$symlink")
  basedir=${basedir#$DOTFILES_DIR} # Note: includes slash at the beginning.

  # Create the required directory structure if one is needed.
  if [ ! -z "$basedir" ] && [ ! -e "${HOME}${basedir}" ]; then
    $(mkdir -p "${HOME}${basedir}")
    echo "Created directory: ${HOME}${basedir}"
  fi

  # Create symlinks.
  # This will produce something like:
  # ln -fs /home/rich/.dotfiles/vimrc.symlink /home/rich/.vimrc
  if [ -z "$basedir" ]; then
    link_at="${HOME}/${name}"
  else
    link_at="${HOME}${basedir}/${name}"
  fi

  # We need to manually unlink directories otherwise it'll create symlink within
  # the directory.
  if [ -d "$symlink" ] && [ -e "$link_at" ]; then
    $(unlink "$link_at")
  fi

  $(ln -fs "${symlink}" "${link_at}")
  echo "Created symlink to ${symlink} at ${link_at}"
done
