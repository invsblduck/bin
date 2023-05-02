#!/bin/bash

PROG_NAME="${0##*/}"
HUB_URL=https://registry.hub.docker.com/v1/repositories

if [ -z "$1" ] || [[ $1 =~ ^--?h(elp)? ]]; then
    echo "usage: ${PROG_NAME} <IMAGE>"
    echo
    echo "List all tags for <IMAGE> on DockerHub"
    exit 1
fi

image="$1"
echo "fetching tags for image \`${image}'..."

curl -sS "${HUB_URL}/${image}/tags" \
    | sed -e 's/[][]//g' -e s/\"//g -e 's/ //g' \
    | tr '}' '\n'  \
    | awk -F: '{print $3}' \
    | sort -V
