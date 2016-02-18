#!/bin/sh
# Inspired by https://github.com/svend/home-bin/blob/master/mutt-uw-search
# This can then be used by mutt in the following way:
#    set query_command = "echo; grep -i '%s' ~/.mutt/book"
# Note: echoing the empty line is necessary for mutt.

host=lonpdc01.citrite.net
port=389
bindDN=CITRITE\\simonbe
pw=$(python /work/mail/imap-pass.py -g simonbe@citrite.net)
base='dc=citrite,dc=net'
sort_by=givenName
max=100

print_results()
{
  mail=
  name=
  title=
  ext=

  while read s; do
    case "$s" in
    dn:*)
      # New entry
      if [ -n "$mail" -a -n "$name" ]; then
        echo -e "$mail\t$name\t$title ext:$ext"
      fi

      # Clear all variables
      mail=
      name=
      title=
      ext=
      ;;
    mail:*)
      mail=${s#mail:[   ]*}
      ;;
    cn:*)
      name=${s#cn:[   ]*}
      ;;
    title:*)
      title=${s#title:[   ]*}
      ;;
    otherTelephone:*)
      ext=${s#otherTelephone:[   ]*}
      ;;
    esac
  done

  # Catch last entry
  if [ -n "$mail" -a -n "$name" ]; then
    echo -e "$mail\t$name\t$title ext:$ext"
  fi
}

filter="(|(objectClass=person)(objectClass=group))"
ldapsearch -h $host -p $port -x -D $bindDN -w $pw -b "$base" -LLL -E pr=500/noprompt "$filter" mail cn title otherTelephone | print_results | sort | uniq
