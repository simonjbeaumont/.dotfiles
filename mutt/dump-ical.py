#!/usr/bin/env python3

import sys
import warnings
import vobject
import datetime
from zoneinfo import ZoneInfo


def get_invitation_from_path(path):
    with open(path) as f:
        try:
            # vobject uses deprecated Exceptions
            with warnings.catch_warnings():
                warnings.simplefilter("ignore")
                return vobject.readOne(f, ignoreUnreadable=True)
        except AttributeError:
            return vobject.readOne(f, ignoreUnreadable=True)


def person_string(c):
    cn = c.params['CN'][0] if 'CN' in c.params else 'unknown'
    return "{} {}".format(cn, "<%s>" % c.value.split(':')[1])


def when_str_of_start_end(s, e):
    datetime_format = "%a, %d %b %Y at %H:%M"

    # sometimes, s and e can be dates only, so convert them to datetimes
    if type(s) == datetime.date:
        s = datetime.datetime.combine(s, datetime.time.min)
    if type(e) == datetime.date:
        e = datetime.datetime.combine(e, datetime.time.min)
    sl = s.astimezone(ZoneInfo('localtime'))
    e = e.astimezone(ZoneInfo('localtime'))

    tz = ""
    if s.tzname() != sl.tzname():
        tz = " (Event timezone: {})".format(s.strftime("%Z"))

    until_format = "%H:%M %Z" if sl.date() == e.date() else datetime_format
    return "{} -- {}{}".format(sl.strftime(datetime_format), e.strftime(until_format), tz)


def pretty_print_invitation(invitation):
    event = invitation.vevent.contents
    title = event['summary'][0].value
    org = event['organizer'][0] if 'organizer' in event else None
    invitees = event['attendee'] if 'attendee' in event else None
    start = event['dtstart'][0].value
    if 'dtend' in event:
        end = event['dtend'][0].value
    elif 'duration' in event:
        end = start + event['duration'][0].value
    else:
        end = start
    location = event['location'][0].value if 'location' in event else None
    description = event['description'][0].value if 'description' in event else None
    sequence = event['sequence'][0].value if 'sequence' in event else None
    rrule = event['rrule'][0].value if 'rrule' in event else None
    print("="*70)
    if sequence is not None and int(sequence) > 0:
        print("MEETING UPDATE".center(70))
    else:
        print("MEETING INVITATION".center(70))
    print("="*70)
    print("Event:\n\t{}".format(title))
    if org:
        print("Organiser:\n\t{}".format(person_string(org)))
    if invitees:
        print("Invitees:")
        for i in invitees:
            print("\t{}".format(person_string(i)))
    print("When:\n\t{}".format(when_str_of_start_end(start, end)))
    if rrule:
        print("Rrule:\n\t{}".format(rrule))
    if location:
        print("Location:\n\t{}".format(location))
    if description:
        print("---\n{}\n---".format(description))


if __name__ == "__main__":
    if len(sys.argv) != 2 or sys.argv[1].startswith('-'):
        sys.stderr.write("Usage: %s <filename.ics>\n".format(sys.argv[0]))
        sys.exit(2)
    inv = get_invitation_from_path(sys.argv[1])
    pretty_print_invitation(inv)
