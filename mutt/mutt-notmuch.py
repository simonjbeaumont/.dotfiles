#!/usr/bin/env python
"""
mutt-notmuch-py
"""

import argparse
import collections
import email
import hashlib
import mailbox
import os
import signal
import subprocess
import sys
import traceback


def digest(path):
    with open(path) as f:
        return hashlib.sha1(f.read()).hexdigest()


def empty_maildir(dir):
    subprocess.call(["mkdir", "-p", "{}/cur".format(dir)])
    subprocess.call(["mkdir", "-p", "{}/new".format(dir)])
    box = mailbox.Maildir(dir)
    box.clear()


def search(query, output_mbox):
    empty_maildir(output_mbox)

    files = subprocess.check_output([
        "notmuch", "search", "--duplicate=1",
        "--output=files", query]).split("\n")

    data = collections.defaultdict(list)
    messages = []
    for f in files:
        if not f:
            continue
        try:
            sha = digest(f)
            data[sha].append(f)
        except IOError:
            sys.stderr.write("File {} does not exist\n".format(f))

    for sha in data:
        messages.append(data[sha][0])

    for m in messages:
        if not m:
            continue
        target = os.path.join(output_mbox, 'cur', os.path.basename(m))
        if not os.path.exists(target):
            os.symlink(m, target)


def thread(message, output_mbox):
    if "message-id" not in message:
        sys.stderr.write("Cannot find message ID")
        sys.exit(1)
    message_id = message["message-id"].strip("<>")
    thread_id = subprocess.check_output([
        "notmuch", "search", "--output=threads",
        "id:{}".format(message_id)]).strip()
    search(thread_id, output_mbox)


def search_command(args):
    query = raw_input('Query: ')
    search(query, args.output_mbox)


def thread_command(args):
    message = email.message_from_file(sys.stdin)
    thread(message, args.output_mbox)


def parse_args_or_exit(argv=None):
    parser = argparse.ArgumentParser(
        description="Notmuch interaction for mutt",
        formatter_class=argparse.ArgumentDefaultsHelpFormatter)
    # common arguments
    parser.add_argument("-o", "--output-mbox", default="~/.cache/mutt_results",
                        help="Output dir for results")
    parser.add_argument("--backtrace", action="store_true",
                        help="Print backtrace on error")
    subparsers = parser.add_subparsers()
    # search command
    subparser = subparsers.add_parser("search", help="Search")
    subparser.set_defaults(func=search_command)
    # thread command
    subparser = subparsers.add_parser("thread", help="Reconstruct thread")
    subparser.set_defaults(func=thread_command)
    return parser.parse_args(argv)


def main(argv):
    args = parse_args_or_exit(argv)
    args.output_mbox = os.path.expanduser(args.output_mbox).rstrip("/")
    try:
        args.func(args)
    except Exception as e:  # pylint: disable=broad-except
        sys.stderr.write("error: {}\n".format(e))
        if args.backtrace:
            traceback.print_exc()
        empty_maildir(args.output_mbox)
        sys.exit(1)


if __name__ == "__main__":
    signal.signal(signal.SIGINT, lambda x, _: sys.exit(128 + x))
    main(sys.argv[1:])
