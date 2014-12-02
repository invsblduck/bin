#!/bin/sh

perl -we 'open MEM, "sudo memstat |";
            while (<MEM>)
            {
               print if /\d\d\d\dk/;
            }
            close MEM;' |ccze -A
