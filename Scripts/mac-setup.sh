#!/bin/zsh

sudo -v

xcode-select --install

compaudit | xargs sudo chmod g-w

brew tap homebrew/cask-fonts

# Assumes homebrew is already installed.
brew install zsh nvim tmux htop node coreutils curl gnupg \
  rsync pv git fzf the_silver_searcher

git clone https://github.com/asdf-vm/asdf.git ~/.asdf --branch v0.8.0

brew install --cask \
  iterm2 \
  google-chrome \
  firefox \
  rectangle \
  zoom \
  slack \
  spotify \
  postman \
  vlc \
  font-source-code-pro




# Configuration things.
defaults write -g com.apple.mouse.scaling -integer -1 # Mouse scaling
defaults write com.apple.menuextra.battery ShowPercent -bool true # Show battery percentage
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool true # Enable tap to click.
defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true # Don't create .DS_Store on network shares.

# Dock
defaults write com.apple.dock autohide 1
defaults write com.apple.dock autohide-delay -float 0
defaults write com.apple.dock autohide-time-modifier -float 0
defaults write com.apple.dock no-bouncing -bool true

chflags nohidden ~/Library
defaults write com.apple.finder AppleShowAllFiles NO
defaults write com.apple.finder ShowPathbar -bool true
defaults write com.apple.finder ShowStatusBar -bool true

defaults write com.google.Chrome AppleEnableSwipeNavigateWithScrolls -bool false
