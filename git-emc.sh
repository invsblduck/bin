#!/bin/bash

DOTRC=~/.git-emc

# NB!: raw controls chars below (don't cut/paste with mouse), sorry.
RED="[01;31m"
DIR="[01;44;33m"
OFF="[0m"

bail() {
    echo "${RED}Exiting.${OFF}"
    exit 1
}

if ! [ -f $DOTRC ]; then
    cat <<EOF
Please create $DOTRC with contents similar to the following:

    USER=       # username for 'hub' command
    EMAIL=      # email address for commits and such
    DIRSPEC=    # word that *SHOULD* be in your CWD when running this script
                # (otherwise we print a warning and prompt)

then run this script again.
EOF
    bail
fi

# source config file
source ~/.git-emc

# set barriers
set -e
trap bail ERR

# find git repo config
gitdir=$(git rev-parse --git-dir)
config=$gitdir/config

# set more barriers
if ! [[ `pwd` =~ $DIRSPEC ]]; then
    cat <<EOF
Your current path is:

    ${DIR}`pwd`${OFF}

EOF
    read -p "${RED}Are you sure you want to modify this repo?${OFF} [y/N]: "
    [[ "$REPLY" =~ ^\s*[yY] ]] || bail
fi

##
# configure email
#
if ! grep -q '^\[user]' $config
then
    echo "==> adding email to repo config"
    cat >>$config <<EOF
[user]
	email = $EMAIL
EOF
else
    echo "[user] section already exists in $config!"
    bail
fi

##
# configure user
#
if ! grep -q '^\[github]' $config; then
    echo "==> adding user to repo config"
    cat >>$config <<EOF
[github]
	username = $USER
EOF
else
    echo "[github] section already exists in $config!"
    bail
fi
