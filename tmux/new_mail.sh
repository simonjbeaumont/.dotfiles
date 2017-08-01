#!/bin/sh

inbox=$(notmuch search "path:Inbox/new" | wc -l)

vip=$(notmuch search "path:Inbox/new AND (from:mdinacci OR from:blaisethom OR from:drummie)" | wc -l)

github=$(notmuch search "path:github/new" | wc -l)

if [[ ${inbox} -gt 0 || ${vip} -gt 0 || ${github} -gt 0 ]]; then
  echo "┃ ✉ i:${inbox} !:${vip} g:${github} "
fi
