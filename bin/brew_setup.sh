#!/bin/bash
# This script is used to setup packages I normally install on OSX via homebrew.

RUBY_VERSION=2.1.3

which -s brew
if [[ $? != 0 ]]; then
  ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
else
  brew update
fi

brew bundle >/dev/null 2>&1
if [[ $? == 0 ]]; then
  brew tap homebrew/boneyard
fi

