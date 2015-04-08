#!/bin/sh

count=$(ls /local/mail/citrix/Inbox/new | wc -l)

if [[ -n "$count"  && "$count" -gt 0 ]]; then
  echo "┃ ✉ ${count} "
fi
