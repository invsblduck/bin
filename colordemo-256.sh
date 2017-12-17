#!/bin/bash   

# See https://en.wikipedia.org/wiki/ANSI_escape_code#8-bit

for i in {0..255} ; do
  printf "\x1b[38;5;${i}mcolor${i} "
done

