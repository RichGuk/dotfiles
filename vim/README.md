# My Vim configuration files

This contains all the Vim plugins and settings I use for myself. I've briefly
tested this on Vim 7.2, however I've since been using 7.3 so any changes I've
made haven't been tested on 7.2.

All the plugins are now installed via [Vundle](https://github.com/gmarik/vundle),
however one submodule does remain (Vundle itself).

### Setup

Clone this repo into your home directory and initialise the snippets submodule.

    cd ~
    git clone http://github.com/RichGuk/vim-files.git .vim
    cd ~/.vim
    git submodule init
    git submodule update

Then in your ~/.vimrc and ~/.gvimrc add the following lines before any personal settings:

**.vimrc**:

    source ~/.vim/vimrc
    ...

**.gvimrc**:

    source ~/.vim/gvimrc
    ...

Then open up Vim and run

    :BundleInstall
