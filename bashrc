# Note: .bashrc is sourced for non-login shells
for file in ~/.{bash_prompt,aliases,functions}; do
    [ -r "$file" ] && source "$file"
done
unset file

# Stop resizing from foobaring readline support
shopt -s checkwinsize

# PATH modifications I've gathered over the years
#-------------------------------------------------------------------------------
# Linux tools and Mac homebrews
[ -r /usr/local/bin ] && export PATH=$PATH:/usr/local/bin
# MacPorts
[ -r /opt/local/bin ] && export PATH=$PATH:/opt/local/bin:/opt/local/sbin
# Citrix
[ -r /usr/groups/xen ] && \
    export PATH=$PATH:/usr/groups/xen/xenuse/bin:/usr/groups/xencore/systems/bin:/usr/groups/xen/xenrt/control:/work/tools


# Make life easier with autocomplete
#-------------------------------------------------------------------------------
if [[ "$OSTYPE" =~ ^darwin ]]; then
    if [ -r /usr/local/etc/bash_completion ]; then
        . /usr/local/etc/bash_completion
    fi
elif [[ "$OSTYPE" =~ ^linux ]]; then
    if [ -r /etc/bash_completion ] && ! shopt -oq posix; then
        . /etc/bash_completion
    fi
fi


# Other sensible(?) environment variables
#-------------------------------------------------------------------------------
export DISPLAY=:0.0
export EDITOR="vim"
export GIT_EDITOR="vim"
export HISTCONTROL=ignoredups # Ignores dupes in the history
# export HISTIGNORE="ls:ls *:cd:cd -:pwd;exit:date:* --help"
export HISTIGNORE="ls:cd:cd -:pwd:exit:date:* --help"
