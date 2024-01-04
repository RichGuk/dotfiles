unsetopt correct_all # disable auto correct

setopt multios # allow multiple redirections, command > file.txt 2>&1 becomes command >| file.txt
setopt auto_cd # cd to directory without typing cd
setopt auto_pushd # pushd when cd
setopt pushd_ignore_dups # ignore duplicated directory when pushd
