# RichGuk's dotfiles

This contains my *$HOME* configuration files. I'm following the method mentioned
[here](https://wiki.archlinux.org/index.php/Dotfiles)
and [here](https://www.atlassian.com/git/tutorials/dotfiles) to manage
the dotfiles.

## Setup

### Manual steps

```bash
git clone --bare --recursive https://github.com/RichGuk/dotfiles.git $HOME/.dotfiles
alias config='/usr/bin/git --git-dir=$HOME/.dotfiles --work-tree=$HOME'

config checkout
config submodule update

config config --local status.showUntrackedFiles no
```

## Tracking files

To add  files to be tracked simply use the normal git commands via the alias.

```bash
config add .config/new-config-file
config add .new-dotfile-to-track
config commit -m 'Added new config files'
config push

```

To remove a file from being tracked and keep it locally use

```bash
config rm --cached .remove-this-dotfile
config push
```

I don't want README.md and INSTALL.md in my home directory, I can access them
via Github/Gitlab web interface. So inform git to the file hasn't changed then
remove them locally.

```bash
config update-index --assume-unchanged README.md INSTALL.md
rm README.md INSTALL.md
```

Should I wish to undo this to edit the files (I normally edit via web)
I can run the following:

```bash
config update-index --no-assume-unchanged README.md
config checkout README.md
config add  README.md
config commit -m 'Updated README.md'
config push
```
