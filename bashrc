# Note: .bashrc is sourced for non-login shells
for file in ~/.{bash_prompt,aliases,functions}; do
    [ -r "$file" ] && source "$file"
done
unset file


# PATH modifications I've gathered over the years
#-------------------------------------------------------------------------------
# Linux tools and Mac homebrews
[ -r /usr/local/bin ] && export PATH=$PATH:/usr/local/bin
# MacPorts
[ -r /opt/local/bin ] && export PATH=$PATH:/opt/local/bin:/opt/local/sbin
# Citrix
[ -r /usr/groups/xen ] && \
    export PATH=$PATH:/usr/groups/xen/xenuse/bin:/usr/groups/xencore/systems/bin


# Make life easier with autocomplete
#-------------------------------------------------------------------------------
if [[ "$OSTYPE" =~ ^darwin ]]; then
    if [ -r `brew --prefix`/etc/bash_completion ]; then
        . `brew --prefix`/etc/bash_completion
    fi
elif [[ "$OSTYPE" =~ ^linux ]]; then
    if [ -r /etc/bash_completion ] && ! shopt -oq posix; then
        . /etc/bash_completion
    fi
fi


# TotalTerminal is pretty neat... start by default for Mac
#-------------------------------------------------------------------------------
if [[ "$OSTYPE" =~ ^darwin ]]; then
    /Applications/TotalTerminal.app/Contents/MacOS/applet 2> /dev/null
fi


# Other sensible(?) environment variables
#-------------------------------------------------------------------------------
export DISPLAY=:0.0
export EDITOR="vim"
export GIT_EDITOR="vim"
export HISTCONTROL=ignoredups # Ignores dupes in the history
export HISTIGNORE="ls:ls *:cd:cd -:pwd;exit:date:* --help"
