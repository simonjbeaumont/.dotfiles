#!/bin/bash

FILTER="$@"

main () {
  people=$(python2 ~/.mutt/pull-ldap.py --host @@HOST@@ --base '@@BASE_PEOPLE@@' --extra-fields @@EXTRA_FIELDS_PEOPLE@@ --filter "${FILTER}" 2>/dev/null) \
  && \
  groups=$(python2 ~/.mutt/pull-ldap.py --host @@HOST@@ --base '@@BASE_GROUPS@@' --extra-fields @@EXTRA_FIELDS_GROUPS@@ --filter "${FILTER}" 2>/dev/null)

  if [[ $? == 4 ]]; then
    echo "--"
    echo "too-many-results"
    echo "--"
  fi

  if [[ "${people}" != "" ]] && [[ "${groups}" != "" ]]; then
    echo "-- People:"
    echo "${people}"
    echo "-- Groups:"
    echo "${groups}"
  elif [[ "${people}" != "" ]]; then
    echo "${people}"
  elif [[ "${groups}" != "" ]]; then
    echo "${groups}"
  fi
}

main
