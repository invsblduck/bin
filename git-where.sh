#!/bin/sh -e

git log --all -M -C --name-only --format='format:' "$@" \
    | grep -v '^$' \
    | sort \
    | uniq -c \
    | sort -n \
    | awk 'BEGIN {print "count\tfile"} {print $1 "\t" $2}' \
    | sort -gr \
    | head -15
