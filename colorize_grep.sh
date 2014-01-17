#!/bin/sh

export ARG=${1:-jiggywiggy}

cat - |\
while read -r line; do
    file="$(echo $line  |sed -r 's/^([^:]*):.*/\1/')"
    match="$(echo "$line" |sed -r 's/^[^:]*:(.*)/\1/')"

    file_hi="[35m${file}[0m"
    match_hi="$(echo "$match" |sed "s/$ARG/[1;31m${ARG}[0m/g")"
    colon_hi="[36m:[0m"

    echo "${file_hi}${colon_hi}${match_hi}"
done
