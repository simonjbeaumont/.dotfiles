#!/bin/bash
set -e

NOTIFICATION_CACHE=/var/tmp/mutt-notification

inbox=$(notmuch search "path:Inbox/new" | wc -l)
team=$(notmuch search "path:lists.siri-vector-platform-team/new" | wc -l)
github=$(notmuch search "path:github/new" | wc -l)

old_notification=$(cat ${NOTIFICATION_CACHE} 2>/dev/null || true)
new_notification="i:${inbox} !:${vip} t:${team} g:${github}"
echo ${new_notification} > ${NOTIFICATION_CACHE}

if [ "${new_notification}" == "${old_notification}" ]; then
  exit 0
fi

title="📫 New Mail"
message="Inbox: ${inbox}   VIP: ${vip}   Team: ${team}   Github: ${github}"

/usr/bin/osascript -e "display notification \"${message}\" with title \"${title}\""
echo -en "\a"
