#!/bin/sh

inbox=$(notmuch search "path:Inbox/new" | wc -l)

# github=$(notmuch search "path:github/new" | wc -l)
github=0

if [ $(( ${inbox} + ${github} )) -eq 0 ]; then
  exit 0
fi

# echo "✉ i:${inbox} g:${github}"
echo "✉ ${inbox}"
# echo "✉️  ${inbox}"
# echo "📥 ${inbox}"
# echo "📨 ${inbox}"
# echo "📬 ${inbox}"
