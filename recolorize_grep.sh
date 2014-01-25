#!/bin/sh

function usage() {
    cat <<EOF
usage: ${0##*/} [-i|--ignore-case] [-w|--word-regexp] [<PATTERN>]

convenience script to colorize grep(1) output differently after a 
lazy grep pipeline. eg.,

    grep --recursive foo /tmp | grep baz | grep blah

if you are using --color with the grep commands above, the final output
contains filenames that are no longer colorized, and there is a smattering
of "blah" highlighted anywhere (even for the filenames themselves, ie.
context is lost from the very first grep in the pipeline).  this script
will re-color the filenames appropriately and only highlight actual
*file content* in the output stream matching <PATTERN>.

EOF
}

#
# parse options
#
TEMP=$(getopt -o hiw -l help,ignore-case,word-regexp -n "${0##*/}" -- "$@")
if [ $? != 0 ]; then
    echo "getopt(1) failed! exiting." >&2
    exit 1
fi


#
# set variables
#
export case=
export word=
export patt=jiggywiggy

export red='[1;31m'
export mag='[35m'
export cyn='[36m'
export end='[0m'

## (quotes required!)
eval set -- "$TEMP"

while true; do
    case "$1" in
        -h|--help)
            usage
            exit 0
            ;;
        -i|--ignore-case)
            case=i
            shift
            ;;
        -w|--word-regexp)
            word=true
            shift
            ;;
        --)
            shift
            break
            ;;
        *)
            echo "Internal error!" >&2
            exit 1
            ;;
    esac
done

# pattern is non-option arg
for arg do patt="$arg" ; done       

# modifiers for sed commands below
export mods="g${case}"

#
# read stdin
#
cat - |\
while read -r line; do
    # organize grep output --
    # separate the filename from actual matching data
    file="$(echo "$line"  |sed -r 's/^([^:]*):.*/\1/')"
    match="$(echo "$line" |sed -r 's/^[^:]*:(.*)/\1/')"

    # colored version of filename and colon character
    file_hi="${mag}${file}${end}"
    colon_hi="${cyn}:${end}"

    # match whole words only?
    if [ -n "$word" ]; then
        # YES.
        # (the colorizing is more complicated)
        match_hi="$(
            echo "$match" \
                |sed -r \
                    -e "s/^(${patt})\$/${red}\1${end}/${mods}" \
                    -e "s/^(${patt})([^a-zA-Z0-9_])/${red}\1${end}\2/${mods}" \
                    -e "s/([^a-zA-Z0-9_])(${patt})([^a-zA-Z0-9_])/\1${red}\2${end}\3/${mods}" \
                    -e "s/([^a-zA-Z0-9_])(${patt})\$/\1${red}\2${end}/${mods}" \
        )"
    else
        # NO.
        # match anywhere in line
        match_hi="$(echo "$match" \
            |sed -r "s/(${patt})/${red}\1${end}/${mods}")"
    fi

    # finally print the colorized line
    echo "${file_hi}${colon_hi}${match_hi}"
done
