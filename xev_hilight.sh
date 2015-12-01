#!/bin/bash

xev |while read line; do
    if [[ $line =~ XLookupString\ gives ]]; then
        echo -e "\e[1;31m${line}\e[0m"
    else
        echo "$line"
    fi
done
