#!/usr/bin/env python

import sys
import warnings
import vobject


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
    return "{} {}".format(c.params['CN'][0], "<%s>" % c.value.split(':')[1])


def when_str_of_start_end(s, e):
    date_format = "%a, %d %b %Y at %H:%M"
    until_format = "%H:%M" if s.date() == e.date() else date_format
    return "{} -- {}".format(s.strftime(date_format), e.strftime(until_format))


def pretty_print_invitation(invitation):
    event = invitation.vevent.contents
    title = event['summary'][0].value
    org = event['organizer'][0]
    invitees = event['attendee']
    start = event['dtstart'][0].value
    end = event['dtend'][0].value
    location = event['location'][0].value
    description = event['description'][0].value
    sequence = event['sequence'][0].value
    print("="*70)
    if int(sequence) > 0:
        print("MEETING UPDATE".center(70))
    else:
        print("MEETING INVITATION".center(70))
    print("="*70)
    print("Event:\n\t{}".format(title))
    print("Organiser:\n\t{}".format(person_string(org)))
    print("Invitees:")
    for i in invitees:
        print("\t{}".format(person_string(i)))
    print("When:\n\t{}".format(when_str_of_start_end(start, end)))
    print("Location:\n\t{}".format(location))
    print("---\n{}---".format(description))


if __name__ == "__main__":
    if len(sys.argv) != 2 or sys.argv[1].startswith('-'):
        sys.stderr.write("Usage: %s <filename.ics>\n".format(sys.argv[0]))
        sys.exit(2)
    inv = get_invitation_from_path(sys.argv[1])
    pretty_print_invitation(inv)
