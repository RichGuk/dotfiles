#!/bin/bash

# This script is used to automatically clone this repo, git submodule init, etc
# and then run the installer.
#
# Should be called like so:
# curl -L http://git.io/richguk-dotsetup | bash
#
cd $HOME
git clone https://github.com/RichGuk/dotfiles.git .dotfiles
cd .dotfiles
git submodule init
git submodule update
./bin/install.sh
cd $HOME
