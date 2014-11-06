#!/bin/bash

RUBY_VERSION=2.1.4

###############################################################################

# Get sudo now, we need it later.
sudo -v


#############################################################
# Brew binaries and apps setup.
##############################################################
which -s brew
if [[ $? != 0 ]]; then
  ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
else
  brew update
fi

binaries=(
  wget
  tmux
  mysql
  postgres
  imagemagick
  python
  ag
  git
  rbenv
  ruby-build
  rbenv-gem-rehash
  rbenv-binstubs
)

echo "installing binaries..."
brew install ${binaries[@]}
brew install vim --override-system-vi


brew install caskroom/cask/brew-cask
#
# apps to look at:
# hazel
#
apps=(
  alfred
  dropbox
  google-chrome
  hipchat
  ynab
  virtualbox
  vagrant
  vlc
  iterm2
  firefox
  cloud
)
echo "installing apps..."
brew install ${apps[@]}
brew cask alfred link

#############################################################
# Setup ruby.
##############################################################
ruby --version | grep ${RUBY_VERSION}
if [[ $? != 0 ]]; then
  rbenv install ${RUBY_VERSION}
  rbenv global ${RUBY_VERSION}

  [[ -s "$HOME/.rbenv" ]] && eval "$(rbenv init -)"

  gem update --system
  gem install bundler foreman rails --no-rdoc --no-ri
fi



# Setup some preferences for OSX.
# Thanks to: https://gist.github.com/brandonb927/3195465
#############################################################
# System.
##############################################################

# Increasing the window resize speed for Cocoa applications
defaults write NSGlobalDomain NSWindowResizeTime -float 0.001

# Expanding the save panel by default
defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode -bool true
defaults write NSGlobalDomain PMPrintingExpandedStateForPrint -bool true
defaults write NSGlobalDomain PMPrintingExpandedStateForPrint2 -bool true

# Save to disk, rather than iCloud by default
defaults write NSGlobalDomain NSDocumentSaveNewDocumentsToCloud -bool false

# Reveal IP address, hostname, OS version, etc. when clicking the clock in the login window
sudo defaults write /Library/Preferences/com.apple.loginwindow AdminHostInfo HostName

# Disable smart quotes and smart dashes
defaults write NSGlobalDomain NSAutomaticQuoteSubstitutionEnabled -bool false
defaults write NSGlobalDomain NSAutomaticDashSubstitutionEnabled -bool false


# Enabling full keyboard access for all controls (enable Tab in modal dialogs, menu windows, etc.)
defaults write NSGlobalDomain AppleKeyboardUIMode -int 3

# Disabling press-and-hold for special keys in favor of key repeat
defaults write NSGlobalDomain ApplePressAndHoldEnabled -bool false

# Setting a blazingly fast keyboard repeat rate
defaults write NSGlobalDomain KeyRepeat -int 0

# Disable auto-correct
defaults write NSGlobalDomain NSAutomaticSpellingCorrectionEnabled -bool false

# Setting trackpad & mouse speed to a reasonable number
defaults write -g com.apple.trackpad.scaling 2
defaults write -g com.apple.mouse.scaling 2.5

# Turn off keyboard illumination when computer is not used for 5 minutes
defaults write com.apple.BezelServices kDimTime -int 300


# Requiring password after sleep or screen saver begins
defaults write com.apple.screensaver askForPassword -int 1
defaults write com.apple.screensaver askForPasswordDelay -int 3

# Enabling subpixel font rendering on non-Apple LCDs
defaults write NSGlobalDomain AppleFontSmoothing -int 2


#############################################################
# Finder.
##############################################################

# Enabling HiDPI display modes (requires restart)
sudo defaults write /Library/Preferences/com.apple.windowserver DisplayResolutionEnabled -bool true

# Don't show icons for hard drives, servers, and removable media on the desktop
defaults write com.apple.finder ShowExternalHardDrivesOnDesktop -bool false

# Show all filename extensions in Finder by default
defaults write NSGlobalDomain AppleShowAllExtensions -bool true

# Show status bar in Finder by default
defaults write com.apple.finder ShowStatusBar -bool true

# Set home as default finder window.
defaults write com.apple.finder NewWindowTarget -string "PfDe"
defaults write com.apple.finder NewWindowTargetPath -string "file://${HOME}"

# Show path bar.
# defaults write com.apple.finder ShowPathbar -bool true

# Disable the warning when changing a file extension
defaults write com.apple.finder FXEnableExtensionChangeWarning -bool false

# Use column view in all Finder windows by default
defaults write com.apple.finder FXPreferredViewStyle Clmv

# Avoid creation of .DS_Store files on network volumes
defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true

# Disable disk image verification
defaults write com.apple.frameworks.diskimages skip-verify -bool true
defaults write com.apple.frameworks.diskimages skip-verify-locked -bool true
defaults write com.apple.frameworks.diskimages skip-verify-remote -bool true

# Allowing text selection in Quick Look/Preview in Finder by default
defaults write com.apple.finder QLEnableTextSelection -bool true


#############################################################
#  Dock.
##############################################################
# Wipe all (default) app icons from the Dock
# (This is only really useful when setting up a new Mac, or if you don't use the Dock to launch apps.)
defaults write com.apple.dock persistent-apps -array

# Setting the icon size of Dock items to 36 pixels for optimal size/screen-realestate
defaults write com.apple.dock tilesize -int 36

# Speeding up Mission Control animations and grouping windows by application
defaults write com.apple.dock expose-animation-duration -float 0.1
defaults write com.apple.dock "expose-group-by-app" -bool true

# Set Dock to auto-hide and remove the auto-hiding delay
defaults write com.apple.dock autohide -bool true
defaults write com.apple.dock autohide-delay -float 0
defaults write com.apple.dock autohide-time-modifier -float 0

# Disable dashboard.
defaults write com.apple.dock dashboard-in-overlay -bool true


#############################################################
# Time Machine
##############################################################
# Prevent Time Machine from prompting to use new hard drives as backup volume
defaults write com.apple.TimeMachine DoNotOfferNewDisksForBackup -bool true

# Disable local Time Machine backups (This can take up a ton of SSD space on <128GB SSDs)
hash tmutil &> /dev/null && sudo tmutil disablelocal


#############################################################
# Iterm2.
##############################################################
# Don't warn about quit.
defaults write com.googlecode.iterm2 Hotkey -bool true

# Setup hotkey as F12.
defaults write com.googlecode.iterm2 HotkeyCode -int 111
defaults write com.googlecode.iterm2 HotkeyChar -int 63247
defaults write com.googlecode.iterm2 HotkeyModifiers -int 8388864
defaults write com.googlecode.iterm2 UseLionStyleFullscreen -bool false
defaults write com.googlecode.iterm2 PromptOnQuit -bool false
# Speed up hotkey
defaults write com.googlecode.iterm2 SplitPaneDimmingAmount -float 0.25


#############################################################
# Activity Monitor
##############################################################
# Show all processes in Activity Monitor
defaults write com.apple.ActivityMonitor ShowCategory -int 0

#############################################################
# Chrome
##############################################################
# Disabling the annoying backswipe in Chrome
defaults write com.google.Chrome AppleEnableSwipeNavigateWithScrolls -bool false




echo "##################################################################"
echo ""
echo "Restart your mac!"
