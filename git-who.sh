#!/bin/sh -e
git log --format='%an' |sort |uniq -c |sort -nr |head
