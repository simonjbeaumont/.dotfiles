#!/bin/sh

inbox=$(notmuch search "path:Inbox/new" | wc -l)

github=$(notmuch search "path:github/new" | wc -l)

if [ $(( ${inbox} + ${github} )) -eq 0 ]; then
  exit 0
fi

echo "✉ i:${inbox} g:${github}"
