#!/bin/sh

TEST_HOST=mail.apple.com

if ! timeout 1 ping -qc1 ${TEST_HOST} >/dev/null 2>&1; then
  echo " VPN: NOT CONNECTED "
fi
