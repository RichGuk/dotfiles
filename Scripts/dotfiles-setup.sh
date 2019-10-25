#!/bin/bash

BACKUP_LOCATION=$HOME/.dotfiles-backup

function config {
  /usr/bin/git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME $@
}

git clone --bare --recursive https://github.com/RichGuk/dotfiles.git $HOME/.dotfiles

config checkout 2>/dev/null

if [ $? -ne 0 ]; then
  echo Backuping up pre-existing dotfiles to $BACKUP_LOCATION
  mkdir -p $BACKUP_LOCATION
  files=$(config checkout 2>&1 | egrep "^\s+" | awk {'print $1'})

  for f in $files; do
    name=$f
    basedir=$(dirname "$f")

    if [ ! -e $BACKUP_LOCATION/$basedir ]; then
      mkdir -p $BACKUP_LOCATION/$basedir
    fi

    mv $f $BACKUP_LOCATION/$f
  done

fi

config checkout
config submodules update
config config status.showUntrackedFiles no
echo "Checked out dotfiles!"
