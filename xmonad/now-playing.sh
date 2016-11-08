#!/bin/sh

/local/home/sjbx/.xmonad/spotify-cli now-playing | \
  cut -d ' ' -f2- | \
  awk -v len=40 '{ if (length($0) > len) print substr($0, 1, len-3) "..."; else print; }' | \
  paste -sd^ | \
  sed 's/\^/ -- /'
