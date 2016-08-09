#!/usr/bin/env python

import argparse
import keyring
import getpass

if __name__ == '__main__':
    SERVICE = 'mbsync'

    parser = argparse.ArgumentParser()
    group = parser.add_mutually_exclusive_group(required=True)
    group.add_argument('--set', '-s', type=str, help='Account to save password')
    group.add_argument('--get', '-g', type=str, help='Account to get password')

    args = parser.parse_args()

    if args.set:
        password = getpass.getpass()
        keyring.set_password(SERVICE, args.set, password)
    else:
        print(keyring.get_password(SERVICE, args.get))
