#!/bin/sh

if [[ -z "${1}" -o  "${1}" =~ ^--?h(elp)? ]]; then
    echo "usage: $0 <PID>"
    exit 1
fi

PID="${1}"
LOG="/tmp/${PID}.log"

sudo gdb -q -batch \
    --eval "attach ${PID}" \
    --eval "call write_history(\"${LOG}\")" \
    --eval 'detach' \
    --eval 'q'

if [ -f "${LOG}" ]; then
    ls -lh "${LOG}"
    exit 0
else
    echo "$0: Not sure if that worked..."
    exit 1
fi
