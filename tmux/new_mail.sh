#!/bin/sh

inbox=$(notmuch search "path:Inbox/new" | wc -l)

team=$(notmuch search "path:lists.siri-vector-platform-team/new" | wc -l)

github=$(notmuch search "path:github/new" | wc -l)

if [[ ${inbox} -gt 0 || ${github} -gt 0 ]]; then
  echo "┃ ✉ i:${inbox} t:${team} g:${github} "
fi
