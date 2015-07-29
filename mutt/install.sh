!/bin/bash

set -x

sudo apt-get install -y \
  mutt-patched \
  msmpt isync \
  notmuch notmuch-mutt \
  ldap-utils \
  urlscan elinks w3m xloadimage python-vobject

(crontab -l; cat crontab-entries) | awk '!x[$0]++' | crontab -
