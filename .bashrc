# Note: .bashrc is sourced for non-login shells
for file in ~/.{extra,bash_prompt,exports,aliases,functions}; do
	[ -r "$file" ] && source "$file"
done
unset file

# PATH modifications I've gathered over the years
export PATH=$PATH:/usr/local/bin:/Developer/usr/bin
# MacPorts
export PATH=/opt/local/bin:/opt/local/sbin:$PATH
# Android SDK
export PATH=/Developer/SDKs/android-sdk-mac_86/tools:$PATH
# CUDA
export PATH=/usr/local/cuda/bin:$PATH
export DYLD_LIBRARY_PATH=/usr/local/cuda/lib:$DYLD_LIBRARY

export VIM_APP_DIR=/Applications/Utilities/MacVim/

# I Like TotalTerminal :) but(!) this is sloooowww :(
/Applications/TotalTerminal.app/Contents/MacOS/applet 2> /dev/null
    
export CLICOLOR=1
export LSCOLORS="cxfxxxxxxxxxxxxxxxGxGx"
export EDITOR="mvim -f"

#-------------------------------------------------------------------------------
# Extra stuff found on https://gist.github.com/102187
#-------------------------------------------------------------------------------
export DISPLAY=:0.0
export EDITOR="mate -w"
export SVN_EDITOR="mate -w"
export GIT_EDITOR='mate -w'
export LC_CTYPE=en_US.UTF-8

export HISTCONTROL=ignoredups # Ignores dupes in the history
export HISTIGNORE="ls:ls *:cd:cd -:pwd;exit:date:* --help"
