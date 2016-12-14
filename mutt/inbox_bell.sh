#!/bin/bash
count=$(ls /Users/Si/work/mail/REMOTE/Inbox/new | wc -l)

if [[ -n "$count" && "$count" -gt 0 ]]; then
  printf '\a'
fi
