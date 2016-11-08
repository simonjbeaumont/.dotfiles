#!/bin/sh

count=$(ls /Users/Si/work/mail/REMOTE/Inbox/new | wc -l)

if [[ -n "$count"  && "$count" -gt 0 ]]; then
  echo "┃ ✉ ${count} "
fi
