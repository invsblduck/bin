[ -z "$1" ] && echo "usage: ${0##*/} <host>" && exit 1
echo -ne "GET /index.html HTTP/1.1\r\n\r\n" |nc $1 80 |grep -i server:
