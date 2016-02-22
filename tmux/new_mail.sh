#!/bin/sh

count=$(ls /work/mail/citrix/Inbox/new | wc -l)

if [[ -n "$count"  && "$count" -gt 0 ]]; then
  echo "┃ ✉ ${count} "
fi
