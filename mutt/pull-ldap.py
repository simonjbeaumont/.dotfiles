#!/usr/bin/env python3

import base64
import subprocess
import argparse
import json
import sys

FIELD_MAIL = "mail"
FIELD_CN = "cn"
REQUIRED_FIELDS = [
    FIELD_MAIL,
    FIELD_CN,
]

ARG_FORMAT_MUTT = "mutt"
ARG_FORMAT_VIM = "vim"


def parse_args_or_exit(argv=None):
    conf_parser = argparse.ArgumentParser(
        description="Query LDAP server for mutt-compliant complete command",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        add_help=False)
    conf_parser.add_argument("-c", "--config",
                             help="Path to config file", metavar="FILE")

    args, remaining_argv = conf_parser.parse_known_args()

    # defaults
    config = {
        "extra_fields": [],
        "mock_input": None,
    }

    if args.config:
        with open(args.config) as f:
            config.update(json.load(f))

    parser = argparse.ArgumentParser(
        description="Query LDAP server for mutt-compliant complete command",
        parents=[conf_parser])
    parser.set_defaults(**config)
    parser.add_argument("--host", required=("host" not in config),
                        help="Address of LDAP server")
    parser.add_argument("--base-people", required=("base_people" not in config),
                        help="Starting point for the person search")
    parser.add_argument("--base-groups", required=("base_groups" not in config),
                        help="Starting point for the group search")
    parser.add_argument("--sortby", default="givenName",
                        help="Sort by this field (default: givenName)")
    parser.add_argument("--extra-fields", nargs="+",
                        help="Extra fields to search and display")
    parser.add_argument("--filter", required=True,
                        help="Search term (part of name)")
    parser.add_argument("--mock-input",
                        help="Use file input instead of server (default: None)")
    parser.add_argument("--dry-run", action="store_true",
                        help="Just print ldapsearch command but don't execute")
    parser.add_argument("--format", choices=[ARG_FORMAT_MUTT, ARG_FORMAT_VIM],
                        default=ARG_FORMAT_MUTT)
    return parser.parse_args(argv)


def ldapsearch(host, base, sortby, filter, fields, dry_run=False):
    ldap_cmd = [
        "ldapsearch",
        "-h", host,
        "-b", base,
        "-LLL",
        "-x",
        "-z", "100",
        "-S", sortby,
        "(|(cn=*{0}*)(mail=*{0}*))".format(filter.strip())
    ] + fields
    if dry_run:
        print(' '.join(["\"{}\"".format(x) for x in ldap_cmd]))
        return ""
    try:
        return subprocess.check_output(ldap_cmd, stderr=subprocess.DEVNULL).decode("utf-8")
    except subprocess.CalledProcessError as e:
        if e.returncode == 4:
            print("--")
            print("too-many-results")
            print("--")
            sys.exit(4)
        raise e


def read_mock_file(path):
    with open(path) as f:
        return f.read()


def remove_first(delim, s):
    return delim.join(s.split(delim)[1:]).strip()


def process_results(lines):
    line_iter = iter(lines.split('\n'))
    results = []
    result = {}
    try:
        while True:
            line = line_iter.__next__()
            if line.startswith("dn:"):
                if all(field in result for field in REQUIRED_FIELDS):
                    results.append(result)
                result = {}
                continue
            (field, _, value) = line.partition(":")
            if value.startswith(": "):
                try:
                    value = base64.b64decode(value)
                except:
                    pass
            result[field] = value.strip()
    except StopIteration:
        if all(field in result for field in REQUIRED_FIELDS):
            results.append(result)
        return results


def print_results_for_mutt(ldap_results, extra_fields):
    for result in ldap_results:
        extra_info = " | ".join([result.get(f, "") for f in extra_fields])
        print("{}\t{}\t{}".format(result[FIELD_MAIL],
                                  result[FIELD_CN],
                                  extra_info))


def print_results_for_vim(ldap_results, extra_fields):
    for result in ldap_results:
        print("{} <{}>".format(result[FIELD_CN], result[FIELD_MAIL]))

def main(argv):
    args = parse_args_or_exit(argv)
    fields = REQUIRED_FIELDS + args.extra_fields + [args.sortby]
    fields = list(set(fields))
    if args.mock_input:
        ldap_results_people, ldap_results_groups = read_mock_file(args.mock_input), None
    else:
        ldap_results_people = ldapsearch(args.host, args.base_people, args.sortby,
                                         args.filter, fields, args.dry_run)
        ldap_results_groups = ldapsearch(args.host, args.base_groups, args.sortby,
                                         args.filter, fields, args.dry_run)
    results_people = process_results(ldap_results_people)
    results_groups = process_results(ldap_results_groups)
    if args.format == ARG_FORMAT_MUTT:
        printer = print_results_for_mutt
    elif args.format == ARG_FORMAT_VIM:
        printer = print_results_for_vim

    printer(results_people, args.extra_fields)


if __name__ == "__main__":
    main(sys.argv[1:])
