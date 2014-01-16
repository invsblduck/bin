#!/bin/bash

tmpfile=`mktemp`
echo "paste lines from weechat:"
cat > $tmpfile

is_url=false
joined=

while read line; do
    [[ $line =~ https?:// ]] && is_url=true

    # nicklist on right, vertical bar in channel
    #trimmed=$(echo $line | sed -e 's/^.*| //' -e 's/[ \t]\o342\o224\o202.*//')

    # buffer list on left
    trimmed=$(echo $line | sed -e 's/^.*\o342\o224\o202 *//')

    [[ $is_url == false ]] && trimmed="$trimmed "  # add space
    joined="${joined}${trimmed}"
done < $tmpfile
rm -f $tmpfile

echo
echo "$joined"
