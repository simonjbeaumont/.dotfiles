#!/bin/bash
set -eou pipefail

log() { printf -- "** %s\n" "$*" >&2; }
error() { printf -- "** ERROR: %s\n" "$*" >&2; }
fatal() { error "$@"; exit 1; }
trap 'error "command failed (line ${LINENO})"' ERR

RUN_ID=$(uuidgen)

log "Starting run ${RUN_ID} at $(date -u +"%Y-%m-%dT%H:%M:%SZ"): $0 $@"


# The tools used are probably installed by Homebrew, need to set the PATH
[ -r "/usr/local/bin" ] && export PATH="/usr/local/bin:$PATH"
[ -r "/opt/brew/bin" ] && export PATH="/opt/brew/bin:$PATH"
which -s brew && export HOMEBREW_PREFIX=$(dirname $(dirname $(which brew)))
[ -r "$HOMEBREW_PREFIX/opt/coreutils/libexec/gnubin" ] && export PATH="$HOMEBREW_PREFIX/opt/coreutils/libexec/gnubin:$PATH"

which -s mbsync || fatal "Required executable not found: mbsync"
which -s notmuch || fatal "Required executable not found: notmuch"
which -s timeout || fatal "Required executable not found: timeout"

case "$1" in
  inbox) TIMEOUT=1m ;;
  other) TIMEOUT=5m ;;
esac

timeout ${TIMEOUT} mbsync -c /Users/Si/.mbsyncrc $1 || fatal "Failed to check for mail"
notmuch new || fatal "Failed to run notmuch"

log "Completed run ${RUN_ID} at $(date -u +"%Y-%m-%dT%H:%M:%SZ")"
