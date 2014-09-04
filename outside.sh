#!/bin/sh -e

# script to comment/uncomment specific lines in a couple files to change the
# color schemes.  makes it easier to see outside :)

SED_OPTS='-ri --follow-symlinks'

VIMRC=~/.vimrc
TERM_CFG=~/.config/terminator/config

if grep -Eq '^ *foreground_color = "#FFFFFF"$' $TERM_CFG; then
    ##
    # make terminal white/bright
    #
    # terminator
    sed $SED_OPTS 's/^( *foreground_color = "#FFFFFF")$/#\1/' $TERM_CFG
    sed $SED_OPTS 's/^#( *background_color = "#FFFFFF")$/\1/' $TERM_CFG
    sed $SED_OPTS 's/^#( *foreground_color = "#000000")$/\1/' $TERM_CFG
    # vim
    sed $SED_OPTS 's/^(color molokai)/"\1/' $VIMRC
    echo "outside colors"
else
    ##
    # make terminal black/dark
    #
    # terminator
    sed $SED_OPTS 's/^#( *foreground_color.*)/\1/' $TERM_CFG
    sed $SED_OPTS 's/^( *background_color = "#FFFFFF")$/#\1/' $TERM_CFG
    sed $SED_OPTS 's/^( *foreground_color = "#000000")$/#\1/' $TERM_CFG
    # vim
    sed $SED_OPTS 's/^"(color molokai)/\1/' $VIMRC
    echo "inside colors"
fi
