#!/bin/bash

if [ "$PWD" != "$HOME/.dotfiles" ]; then
    echo "Please execute bootstap.sh from .dotfiles directory in $HOME"
else
    # Check we're up to date
    git pull
    
    [ -f "$HOME/.aliases"  ] && rm "$HOME/.aliases"
    [ -f "$HOME/.bash_profile"  ] && rm "$HOME/.bash_profile"
    [ -f "$HOME/.bash_prompt"  ] && rm "$HOME/.bash_prompt"
    [ -f "$HOME/.bashrc"  ] && rm "$HOME/.bashrc"
    [ -f "$HOME/.functions"  ] && rm "$HOME/.functions"
    [ -f "$HOME/.gitconfig"  ] && rm "$HOME/.gitconfig"
    [ -f "$HOME/.gitignore_global"  ] && rm "$HOME/.gitignore_global"
    [ -f "$HOME/.inputrc"  ] && rm "$HOME/.inputrc"
    
    ln -sv "$HOME/.dotfiles/.aliases" "$HOME/.aliases"
    ln -sv "$HOME/.dotfiles/.bash_profile" "$HOME/.bash_profile"
    ln -sv "$HOME/.dotfiles/.bash_prompt" "$HOME/.bash_prompt"
    ln -sv "$HOME/.dotfiles/.bashrc" "$HOME/.bashrc"
    ln -sv "$HOME/.dotfiles/.functions" "$HOME/.functions"
    ln -sv "$HOME/.dotfiles/.gitconfig" "$HOME/.gitconfig"
    ln -sv "$HOME/.dotfiles/.gitignore_global" "$HOME/.gitignore_global"
    ln -sv "$HOME/.dotfiles/.inputrc" "$HOME/.inputrc"

    # if we're on a Mac, let's set it up properly
    if [[ "$OSTYPE" =~ ^darwin ]]; then
    	source "$HOME/.dotfiles/.osx"
    fi

    source ~/.bash_profile
    cd "$HOME"
    echo "Initalisation complete!"
fi
