#!/bin/bash

name="$1"

DOTRC=~/.git-${name}

# NB!: raw controls chars below (don't cut/paste with mouse), sorry.
RED="[01;31m"
YLW="[01;33m"
DIR="[01;44;33m"
OFF="[0m"

bail() {
    echo "${RED}Exiting.${OFF}"
    exit 1
}

ignore() {
    echo "${YLW}Ignoring.${OFF}"
}

if ! [ -f $DOTRC ]; then
    cat <<EOF
Please create $DOTRC with contents similar to the following:

    GIT_USER=       # Github username
    GIT_PASS=       # Github password
    GIT_EMAIL=      # email address for commits and such
    GIT_DIRSPEC=    # word that *SHOULD* be in your CWD when running this script

then run this script again.
EOF
    bail
fi

# source config file
source $DOTRC

# set barriers
set -e
trap bail ERR

# find git repo config
gitdir=$(git rev-parse --git-dir)
config=$gitdir/config

# set more barriers
if ! [[ `pwd` =~ $GIT_DIRSPEC ]]; then
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
	email = $GIT_EMAIL
EOF
else
    echo "[user] section already exists in $config!"
    ignore
fi

##
# configure hub username
#
if ! grep -q '^\[github]' $config; then
    echo "==> adding user to repo config"
    cat >>$config <<EOF
[github]
	user = $GIT_USER
EOF
else
    echo "[github] section already exists in $config!"
    ignore
fi

##
# configure hub username
#
# if grep -Eq '^[[:space:]]*url = https://github\.emcrubicon\.com' $config; then
#     echo "==> updating remote with user/pass"
#     sed -i -r "s#^([[:space:]]*url = https://)(github\\.emcrubicon\\.com.*)#\1${GIT_USER}:${GIT_PASS}@\2#" $config
# fi
