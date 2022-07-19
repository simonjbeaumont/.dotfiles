#!/bin/bash
set -euo pipefail

USAGE="usage: $0 <root-maildir-folder>"
ROOT=${1:?"${USAGE}"}

find "${ROOT}"/* -type d ! -name cur ! -name tmp ! -name new ! -name .notmuch -exec echo -n '"{}" ' \;
