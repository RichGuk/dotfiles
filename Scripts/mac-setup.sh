#!/bin/zsh

sudo -v

xcode-select --install

compaudit | xargs sudo chmod g-w

brew install zsh nvim tmux htop node coreutils curl gnupg \
  rsync pv git svn fzf ripgrep jq neovim iproute2mac wakeonlan

git clone https://github.com/asdf-vm/asdf.git ~/.asdf --branch v0.14.0

brew install --cask \
  google-chrome \
  karabiner-elements \
  firefox \
  linearmouse \
  slack \
  spotify \
  vlc \
  zerotier-one \
  raycast \
  shottr \
  browserosaurus \
  obsidian \
  docker \
  bartender \
  font-fira-code

defaults write -g ApplePressAndHoldEnabled -bool false

# Configuration things.
defaults write -g com.apple.mouse.scaling -integer -1
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool true
defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true
defaults write com.apple.finder FXEnableExtensionChangeWarning -bool false
defaults write -g AppleEnableMenuBarTransparency -bool false
defaults -currentHost write -g AppleFontSmoothing -int 0
defaults write NSGlobalDomain AppleFontSmoothing -int 1
defaults write com.apple.screencapture disable-shadow -bool true

 defaults write com.apple.screensaver askForPassword -int 1
 defaults write com.apple.screensaver askForPasswordDelay -int 2

# Key repeat.
defaults write -g InitialKeyRepeat -int 15
defaults write -g KeyRepeat -int 2

# Dock
defaults write com.apple.dock autohide -bool true
defaults write com.apple.dock autohide-delay -float 1000
defaults write com.apple.dock autohide-time-modifier -float 0
defaults write com.apple.dock no-bouncing -bool true
killall Dock

# Mission Control
defaults write com.apple.dock mru-spaces -bool false
defaults write -g AppleSpacesSwitchOnActivate -bool false
defaults write com.apple.spaces spans-displays -bool true
 defaults write com.apple.dock expose-animation-duration -float 0.1

chflags nohidden ~/Library
defaults write com.apple.finder AppleShowAllFiles NO
defaults write com.apple.finder ShowPathbar -bool true
defaults write com.apple.finder ShowStatusBar -bool true

defaults write com.google.Chrome AppleEnableSwipeNavigateWithScrolls -bool false

defaults write ~/Library/Preferences/ByHost/com.apple.controlcenter.plist BatteryShowPercentage -bool true
defaults write com.apple.TimeMachine DoNotOfferNewDisksForBackup -bool true
