!/bin/bash

set -ex

sudo apt-get install -y \
  mutt-patched \
  msmtp isync \
  notmuch notmuch-mutt \
  ldap-utils \
  urlscan elinks w3m xloadimage python-vobject

(crontab -l; cat crontab-entries) | awk '!x[$0]++' | crontab -

mkdir -p /work/mail/citrix
ln -sfb $PWD/imap-pass.py /work/mail/imap-pass.py

echo "Please run: python ./imap-pass.py -s simonbe@citrite.net"
