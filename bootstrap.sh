#!/bin/bash

# install_dotfile (file, dst)
# --
# If the destination already exists then overwrite it iff it is a symlink,
# otherwise leave it alone

set +ev

install_dotfile () {
    if [ ! -d $(dirname $2) ]; then
        echo "Skipping $2: destination directory does not exist"
        return
    fi

    if [ -e $2 -a ! -h $2 ]; then
        echo "Skipping $2: installing would overwrite non-symlink"
        return
    fi

    echo -n "Linking $2..."
    ln -sf $1 $2
    echo "done"
}

if [ "$PWD" != "$HOME/.dotfiles" ]; then
    echo "Please execute bootstap.sh from .dotfiles directory in $HOME"
    exit 1
fi

# Check we're up to date
git pull

# Add links to these files
install_dotfile "$HOME/.dotfiles/bash/aliases" "$HOME/.aliases"
install_dotfile "$HOME/.dotfiles/bash/bash_profile" "$HOME/.bash_profile"
install_dotfile "$HOME/.dotfiles/bash/bash_prompt" "$HOME/.bash_prompt"
install_dotfile "$HOME/.dotfiles/bash/bashrc" "$HOME/.bashrc"
install_dotfile "$HOME/.dotfiles/bash/dircolors.solarized_ansi_dark" "$HOME/.dircolors"
install_dotfile "$HOME/.dotfiles/bash/functions" "$HOME/.functions"
install_dotfile "$HOME/.dotfiles/bash/inputrc" "$HOME/.inputrc"
install_dotfile "$HOME/.dotfiles/git/gitconfig" "$HOME/.gitconfig"
install_dotfile "$HOME/.dotfiles/git/gitignore_global" "$HOME/.gitignore_global"
install_dotfile "$HOME/.dotfiles/hg/hgrc" "$HOME/.hgrc"
install_dotfile "$HOME/.dotfiles/hg/hgignore" "$HOME/.hgignore"
install_dotfile "$HOME/.dotfiles/irssi" "$HOME/.irssi"
install_dotfile "$HOME/.dotfiles/mutt" "$HOME/.mutt"
install_dotfile "$HOME/.dotfiles/mutt/msmtprc" "$HOME/.msmtprc"
install_dotfile "$HOME/.dotfiles/mutt/mbsyncrc" "$HOME/.mbsyncrc"
install_dotfile "$HOME/.dotfiles/mutt/notmuch-config" "$HOME/.notmuch-config"
install_dotfile "$HOME/.dotfiles/tmux/tmux.conf" "$HOME/.tmux.conf"
install_dotfile "$HOME/.dotfiles/tmux/tmux-powerline/tmux-powerlinerc" "$HOME/.tmux-powerlinerc"
install_dotfile "$HOME/.dotfiles/vim" "$HOME/.vim"
install_dotfile "$HOME/.dotfiles/vim/vimrc" "$HOME/.vimrc"
install_dotfile "$HOME/.dotfiles/vimperator" "$HOME/.vimperator"
install_dotfile "$HOME/.dotfiles/vimperator/vimperatorrc" "$HOME/.vimperatorrc"
install_dotfile "$HOME/.dotfiles/ssh/config" "$HOME/.ssh/config"
install_dotfile "$HOME/.dotfiles/utoprc" "$HOME/.utoprc"

# OS specific config
case "$OSTYPE" in
    darwin*)
        source "$HOME/.dotfiles/osx/osx-defaults-setup"
        echo "Note: Terminal.app and iTerm themes can be installed from:"
        echo "  - $HOME/.dotfiles/osx/"
        ;;
    linux*)
        install_dotfile "$HOME/.dotfiles/linux/xinitrc" "$HOME/.xinitrc"
        install_dotfile "$HOME/.dotfiles/linux/Xmodmap" "$HOME/.Xmodmap"
        xmodmap "$HOME/.Xmodmap"
        install_dotfile "$HOME/.dotfiles/xmonad/xmonad.hs" "$HOME/.xmonad/xmonad.hs"
        install_dotfile "$HOME/.dotfiles/xmonad/xmobarrc" "$HOME/.xmonad/xmobarrc"
        install_dotfile "$HOME/.dotfiles/xmonad/icons" "$HOME/.xmonad/icons"
        ;;
esac

# let's sort out all the vim submodules
git submodule init
git submodule update
vi -c :VundleInstall -c :qall

source ~/.bash_profile
cd "$HOME"
echo "Initalisation complete!"
