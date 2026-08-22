# Enable highlighters
ZSH_HIGHLIGHT_HIGHLIGHTERS=(main brackets pattern)

# zsh-syntax-highlighting must be sourced last, after every other ZLE widget
# is defined (see its INSTALL.md); the catppuccin theme only sets its styles.
source ${0:h}/zsh-autosuggestions/zsh-autosuggestions.zsh
source ${0:h}/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
source ${0:h}/catppuccin-zsh-syntax-highlighting/themes/catppuccin_mocha-zsh-syntax-highlighting.zsh
