!/bin/bash

set -x

sudo apt-get install -y mutt notmuch notmuch-mutt ldap-utils python-vobject
(crontab -l; cat crontab-entries) | awk '!x[$0]++' | crontab -
