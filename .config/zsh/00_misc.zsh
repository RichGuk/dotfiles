setopt multios # tee to multiple targets, command > one.txt > two.txt
setopt interactive_comments # allow # comments at the interactive prompt
setopt no_beep
setopt auto_cd # cd to directory without typing cd
setopt auto_pushd # pushd when cd
setopt pushd_ignore_dups # ignore duplicated directory when pushd

[[ -t 0 ]] && stty -ixon # ctrl+s is the herdr prefix, not XOFF
