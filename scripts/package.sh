#!/bin/sh
set -eu
root=$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)
archive=${1:?Provide an output archive path}
case "$archive" in /*) ;; *) archive="$PWD/$archive" ;; esac
tar -czf "$archive" -C "$root" README.md README.en.md LICENSE lua ftplugin indent syntax doc tests
printf 'Created %s\n' "$archive"
