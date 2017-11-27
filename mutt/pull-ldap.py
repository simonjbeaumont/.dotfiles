#!/usr/bin/env python

import base64
import subprocess
import argparse
import sys

FIELD_MAIL = "mail"
FIELD_CN = "cn"
REQUIRED_FIELDS = [
    FIELD_MAIL,
    FIELD_CN,
]


def parse_args_or_exit(argv=None):
    parser = argparse.ArgumentParser(
        description="Query LDAP server for mutt-compliant complete command")
    parser.add_argument("--host", required=True,
                        help="Address of LDAP server")
    parser.add_argument("--base", required=True,
                        help="Starting point for the search")
    parser.add_argument("--sortby", default="givenName",
                        help="Sort by this field (default: givenName)")
    parser.add_argument("--extra-fields", nargs="+", default=[],
                        help="Extra fields to search and display")
    parser.add_argument("--filter", required=True,
                        help="Search term (part of name)")
    parser.add_argument("--mock-input", default=None,
                        help="Use file input instead of server (default: None)")
    parser.add_argument("--dry-run", action="store_true",
                        help="Just print ldapsearch command but don't execute")
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
        print ' '.join(["\"{}\"".format(x) for x in ldap_cmd])
        return ""
    try:
        return subprocess.check_output(ldap_cmd)
    except subprocess.CalledProcessError as e:
        if e.returncode == 4:
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
            line = line_iter.next()
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
        print "{}\t{}\t{}".format(result[FIELD_MAIL],
                                  result[FIELD_CN],
                                  extra_info)


def main(argv):
    args = parse_args_or_exit(argv)
    fields = REQUIRED_FIELDS + args.extra_fields + [args.sortby]
    fields = list(set(fields))
    if args.mock_input:
        ldap_results = read_mock_file(args.mock_input)
    else:
        ldap_results = ldapsearch(args.host, args.base, args.sortby,
                                  args.filter, fields, args.dry_run)
    results = process_results(ldap_results)
    print_results_for_mutt(results, args.extra_fields)


if __name__ == "__main__":
    main(sys.argv[1:])
