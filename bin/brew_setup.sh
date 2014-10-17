#!/bin/bash
# This script is used to setup packages I normally install on OSX via homebrew.

RUBY_VERSION=2.1.3

which -s brew
if [[ $? != 0 ]]; then
  ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
else
  brew update
fi

git version | grep Apple
if [[ $? == 0 ]]; then
  brew install git
fi

which -s tmux
if [[ $? != 0 ]]; then
  brew install tmux
fi

which -s rbenv
if [[ $? != 0 ]]; then
  brew install rbenv
  brew install ruby-build
  brew install rbenv-gem-rehash
  brew install rbenv-binstubs

  rbenv install ${RUBY_VERSION}
  rbenv global ${RUBY_VERSION}

  [[ -s "$HOME/.rbenv" ]] && eval "$(rbenv init -)"

  gem update --system
  gem install bundler foreman rails --no-rdoc --no-ri
fi

which -s mysql
if [[ $? != 0 ]]; then
  brew install mysql
  mysql.server start
  mysql_secure_installation
fi

which -s postgres
if [[ $? != 0 ]]; then
  brew install postgres
fi
