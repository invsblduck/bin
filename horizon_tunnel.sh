#!/bin/sh
if [ $# -ne 2 ]
then
    cat <<EOF
usage: ${0##*/} <bounce_host> <target_host>"

opens local port 65000 that redirects to port 443 on <target_host>.
<bounce_host> is the proxy host to ssh to.

EOF
    exit 1
fi

# TODO check for existing tunnel
# TODO ping bounce host
# TODO take user argument
# TODO accept password
# TODO verify tunnel connected
echo "establishing tunnel..."
nohup ssh -f -N -L 65000:$2:443 $1 </dev/null &>/dev/null &

if [ $? != 0 ]
then
    echo "failed :("
    exit 1
fi
