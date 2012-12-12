#!/bin/bash

if [ "$PWD" != "$HOME/.dotfiles" ]; then
    echo "Please execute bootstap.sh from .dotfiles directory in $HOME"
else
    # Check we're up to date
    git pull

    # Remove other files
    [ -e "$HOME/.aliases" -o -h "$HOME/.aliases" ] && rm -v "$HOME/.aliases"
    [ -e "$HOME/.bash_profile" -o -h "$HOME/.bash_profile" ] && rm -v "$HOME/.bash_profile"
    [ -e "$HOME/.bash_prompt" -o -h "$HOME/.bash_prompt" ] && rm -v "$HOME/.bash_prompt"
    [ -e "$HOME/.bashrc" -o -h "$HOME/.bashrc" ] && rm -v "$HOME/.bashrc"
    [ -e "$HOME/.functions" -o -h "$HOME/.functions" ] && rm -v "$HOME/.functions"
    [ -e "$HOME/.gitconfig" -o -h "$HOME/.gitconfig" ] && rm -v "$HOME/.gitconfig"
    [ -e "$HOME/.gitignore_global" -o -h "$HOME/.gitignore_global" ] && rm -v "$HOME/.gitignore_global"
    [ -e "$HOME/.hgrc" -o -h "$HOME/.hgrc" ] && rm -v "$HOME/.hgrc"
    [ -e "$HOME/.hgignore" -o -h "$HOME/.hgignore" ] && rm -v "$HOME/.hgignore"
    [ -e "$HOME/.inputrc" -o -h "$HOME/.inputrc" ] && rm -v "$HOME/.inputrc"
    [ -e "$HOME/.vim" -o -h "$HOME/.vim" ] && rm -r -v "$HOME/.vim"
    [ -e "$HOME/.vimrc" -o -h "$HOME/.vimrc" ] && rm -v "$HOME/.vimrc"
    [ -e "$HOME/.xmonad/xmonad.hs" -o -h "$HOME/.xmonad/xmonad.hs" ] && rm -v "$HOME/.xmonad/xmonad.hs"

    # Add links to these files
    ln -sv "$HOME/.dotfiles/aliases" "$HOME/.aliases"
    ln -sv "$HOME/.dotfiles/bash_profile" "$HOME/.bash_profile"
    ln -sv "$HOME/.dotfiles/bash_prompt" "$HOME/.bash_prompt"
    ln -sv "$HOME/.dotfiles/bashrc" "$HOME/.bashrc"
    ln -sv "$HOME/.dotfiles/functions" "$HOME/.functions"
    ln -sv "$HOME/.dotfiles/gitconfig" "$HOME/.gitconfig"
    ln -sv "$HOME/.dotfiles/gitignore_global" "$HOME/.gitignore_global"
    ln -sv "$HOME/.dotfiles/hg-files/hgrc" "$HOME/.hgrc"
    ln -sv "$HOME/.dotfiles/hg-files/hgignore" "$HOME/.hgignore"
    ln -sv "$HOME/.dotfiles/inputrc" "$HOME/.inputrc"
    ln -sv "$HOME/.dotfiles/.vim" "$HOME/.vim"
    ln -sv "$HOME/.dotfiles/vimrc" "$HOME/.vimrc"
    [ -e "$HOME/.xmonad" -a -d "$HOME/.xmonad" ] && ln -sv "$HOME/.dotfiles/xmonad.hs" "$HOME/.xmonad/xmonad.hs"

    # if we're on a Mac, let's set it up properly
    if [[ "$OSTYPE" =~ ^darwin ]]; then
    	source "$HOME/.dotfiles/osx"
    fi

    source ~/.bash_profile
    cd "$HOME"
    echo "Initalisation complete!"
fi
