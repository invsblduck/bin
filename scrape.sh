#!/bin/sh

if [ -z "$1" ] || [ -z "$2" ] || [ -z "$3" ]
then
   echo "usage: $0 <archive> <subject> <dates_file>"
   exit 1
fi

archive=$1
subject=$2
datesfile=$3

date=`date +%b`-`date +%d`-`date +%H`:`date +%M`
basedir=/data/mail-archives/search
targdir=$basedir/$subject-$date

[ ! -d $targdir ] && mkdir $targdir

for entry in `cat $datesfile`
do
   ml.pl -a $archive -d $entry -s "$subject" -n -h -o ${targdir}/${archive}-${entry}-${subject}.html
done

echo
echo "generating index-$date.html file ..."
cd $targdir
cat >index-$date.html <<?EOF?
<html><head><title>$archive search '$subject'</title></head>
<body bgcolor='black'><font color='white'><h1>$archive search for "$subject"</h1>
?EOF?

for result in `ls -ltr | grep -vi '^total' | awk '{ print $9 }'`
do
   if [ "$result" != "index-$date.html" ]
   then
      echo "<a href='$result'> $result </a><br>" >>index-$date.html
   fi
done

echo "</font></body></html>" >>index-$date.html

read -n1 -p "browse $targdir/index-$date.html ? [Y/n]: " browse
if [ -z "$browse" ] || [ "$browse" = "y" ]
then
   firefox file://$targdir/index-$date.html
fi
