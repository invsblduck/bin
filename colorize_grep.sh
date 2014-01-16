#!/bin/sh
cat - \
    |sed -r 's/^([^:]*):(.*)/[35m\1[36m:[0m\2/' \
    |sed "s/${1:-jiggywiggy}/[1;31m${1:-jiggywiggy}[0m/g"
