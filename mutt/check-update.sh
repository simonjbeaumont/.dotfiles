#!/bin/bash
echo $(date) $0 $@
/usr/local/opt/coreutils/libexec/gnubin/timeout 1m /usr/local/bin/mbsync -c /Users/Si/.mbsyncrc $1
/usr/local/bin/notmuch new
