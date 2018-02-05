#!/bin/bash
set -eou pipefail

echo $(date) $0 $@

case "$1" in
  inbox) TIMEOUT=1m ;;
  other) TIMEOUT=5m ;;
esac

/usr/local/opt/coreutils/libexec/gnubin/timeout ${TIMEOUT} /usr/local/bin/mbsync -c /Users/Si/.mbsyncrc $1 || echo "TIMEOUT"

/usr/local/bin/notmuch new

echo $(date) $0 $@ done
