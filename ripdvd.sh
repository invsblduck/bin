#! /bin/bash

mount=/cdrom
destdir=/data/media/rip

cd "$destdir"

function cleanup
{
   rm -f "$destdir/frameno.avi"
   rm -f "$destdir/divx2pass.log"
   rm -f /tmp/prev_$filename 
   #rm -f "$destdir/*.[vv][oO][bB]"
   rm -f /tmp/lsdvd.log
   rm -f /tmp/frameno.log
}


#
# copy vob ?
#
rip_vob=y

read -n1 -p "rip from DVD? [Y/n]: " next
[ -n "$next" ] && echo
[ "$next" = "n" ] && rip_vob=n

#
# niceness
#
read -n1 -p "nice +19? [Y/n]: " nicer
[ -n "$nicer" ] && echo

if [ -z "$nicer" -o "$nicer" = "y" ]
then
   NICENESS='nice -+19'
else
   NICENESS=
fi


#
# lsdvd
#

if [ "$rip_vob" = "y" ]
then
   while [ "$rip" != "d" -a "$rip" != "f" ]; do
      read -n1 -p "rip to (d)isk or on-(f)ly? [d/F]: " rip
      [ -z "$rip" ] && rip=f && break;
      [ -n "$rip" ] && echo;
   done

   echo
   echo -n "gathering DVD information... "

   lsdvd -x >/tmp/lsdvd.log 2>/dev/null || \
   ( echo "lsdvd failed to get info." && exit 1 )


   disc_title=`head -1 /tmp/lsdvd.log |awk '{ print $3 }'`

   longest_title=`tail -1 /tmp/lsdvd.log |awk '{ print $3 }'`
   len_longest_title=`grep Title:\ 0$longest_title /tmp/lsdvd.log |awk '{ print $4 }'`

   echo
   echo " --> name of DVD is $disc_title"
   echo " --> longest title is track $longest_title @ [ $len_longest_title ]"
   echo

   echo -n "track number [$longest_title]: "
   read titleno ; [ -z "$titleno" ] && titleno=$longest_title
else
   rip=d

   echo
   echo "the VOB _must_ be in $destdir !"
   echo -n "full name of VOB file: "
   read vobname

   disc_title=`basename $vobname .vob`
fi


#
# vobcopy
#

if [ "$rip_vob" = "y" -a "$rip" = "d" ]
then
   if mount |grep -q cdrom 2>/dev/null
   then
      read -n1 -p "cdrom already mounted. continue? [Y/n]: " go
      [ -n "$go" -a "$go" = "n" ] && echo && exit 1
      [ -n "$go" ] && echo
   else
      mount $mount || ( echo "could not mount $mount" && exit 1 )
   fi

   if ls ${disc_title}.vob >/dev/null 2>&1
   then
      echo "i found an existing VOB:"
      ls -lh --color=auto ${disc_title}.vob
      
      echo
      read -n1 -p "would you like to use the existing file? [Y/n]: " use

      if [ -n "$use" ]; then
         echo
         [ "$use" != y ] && $NICENESS vobcopy -l -v -n "$titleno" -o "$destdir"
      fi

   else
      $NICENESS vobcopy -l -v -n "$titleno" -o "$destdir"

      eject

      echo
      echo "(VOB rip complete; control-c [SIGINT] to kill)"
      echo
   fi
fi


suggested_filename="`echo $disc_title |tr '[:upper:]' '[:lower:]'`.avi"

echo -n "title of film [$disc_title]: "
read title ; [ -z "$title" ] && title=$disc_title

echo -n "output filename (AVI format) [$suggested_filename]: "
read filename ; [ -z "$filename" ] && filename=$suggested_filename

echo
cd "$destdir"


#############################################################################
#
# Encoding pass 1 (audio). This will also calculate video bitrates.
#
#############################################################################

audioid=128     # english

if ls frameno.avi >/dev/null 2>&1
then
   echo "i found an existing audio file: "
   ls -lh --color=auto frameno.avi
   
   echo
   read -n1 -p "would you like to use this file? [Y/n]: " use_existing

   [ -n "$use_existing" ] && echo
   if [ -z "$use_existing" -o "$use_existing" = "y" ]; then
      rip_audio=n
      if ! ls /tmp/frameno.log >/dev/null 2>&1
      then
         echo " -!!!- Warning: audio log does not exist!"
         echo " -!!!- i will not be able to calculate bitrates for you."
         echo
         echo "you will have to supply the bitrate yourself!"
         read -n1 -p "continue? [y/N]: " next
         [ -z "$next" -o "$next" != "y" ] && echo && exit 1
      fi

   else
      echo " --> clobbering old frameno.avi!"
      rm -f frameno.avi
   fi
fi
echo

if [ "$rip_audio" != "n" ]
then
   if [ "$rip" = "f" ]; then
      $NICENESS mencoder -dvd $titleno -aid $audioid -ovc frameno \
      -o frameno.avi -oac mp3lame -lameopts abr:br=128:q=3:vol=8 \
      |tee /tmp/frameno.log
   else
      $NICENESS mencoder -aid $audioid -ovc frameno -o frameno.avi \
      -oac mp3lame -lameopts abr:br=128:q=3:vol=8 "${disc_title}.vob" \
      |tee /tmp/frameno.log
   fi
fi


#
# get video bitrate
#

cat <<EOF
select target medium:

   a) one 650MB CD
   b) one 700MB CD
   c) one 800MB CD

   d) two 650MB CD
   e) two 700MB CD
   f) two 800MB CD

   g) enter bit-rate

EOF

while [ "$ok" != "y" ]; do
   read -n1 -p "selection [b]: " choice
   [ -n "$choice" ] && echo
   [ -z "$choice" ] && choice=b

   case "$choice" in
      a)
         vbr=`tail -15 /tmp/frameno.log |grep 650MB |head -1 |awk '{ print $7 }'`
         ok=y
         ;;
      b)
         vbr=`tail -15 /tmp/frameno.log |grep 700MB |head -1 |awk '{ print $7 }'`
         ok=y
         ;;
      c)
         vbr=`tail -15 /tmp/frameno.log |grep 800MB |head -1 |awk '{ print $7 }'`
         ok=y
         ;;
      d)
         vbr=`tail -15 /tmp/frameno.log |grep 650MB |tail -1 |awk '{ print $7 }'`
         ok=y
         ;;
      e)
         vbr=`tail -15 /tmp/frameno.log |grep 700MB |tail -1 |awk '{ print $7 }'`
         ok=y
         ;;
      f)
         vbr=`tail -15 /tmp/frameno.log |grep 800MB |tail -1 |awk '{ print $7 }'`
         ok=y
         ;;
      g)
         echo -n "video bitrate? "
         read vbr
         ok=y
         ;;
      *)
         ok=n
         ;;
   esac
done

if [ -z "$vbr" ]; then
   echo -n "video bitrate? "
   read vbr
fi

[ "$choice" != g ] && echo "\nvideo bitrate will be $vbr"

# old stuff

   #echo "$titlelen"
   #echo -n "enter length of film in seconds: "
   #read seconds

   #MAXSIZE=700000      # 700 MB CD
   #minutes=$(($seconds/60))
   #audiorate=$((16*$seconds))
   #crazyrate=$(($MAXSIZE - $audiorate))
   #vbr=$((($crazyrate * 8) / $seconds))

   #echo
   #echo "estimated video bit rate: $vbr"

   #finalsize=$((($vbr * $seconds)/8 + $audiorate))
   #echo "estimated final .AVI size: $finalsize"


#
# crop detect
#
read -n1 -p "crop image? [y/N]: " crop
[ -n "$crop" ] && echo

if [ "$crop" = "y" ]
then
   echo
   echo "using autocrop to estimate crop boundaries ....."
   echo "(this isn't the most reliable thing in the world)"
   echo
   echo "USE CONTROL-\ [SIGQUIT] TO TERMINATE."
   echo
   read -n1 -p " --> 0x0d to continue " next
   echo

   if [ "$rip" = "f" ]
   then
      mencoder -dvd $titleno -sws 2 -ovc lavc \
      -lavcopts vcodec=mpeg4:vhq:vbitrate=$vbr -vop cropdetect,scale \
      -zoom -xy 640 -oac copy -o /dev/null 
   else
      mencoder -sws 2 -ovc lavc -lavcopts vcodec=mpeg4:vhq:vbitrate=$vbr \
      -vop cropdetect,scale -zoom -xy 640 -oac copy -o /dev/null \
      "${disc_title}.vob"
   fi

   echo
   echo -n "crop boundaries: "
   read autocrop
   echo 
else
   autocrop='0:0:-1:-1'   # use defaults
fi


read -n1 -p "generate a short preview? [y/N]: " preview 
[ -n "$preview" ] && echo

if [ "$preview" = "y" ]; then
   err=
   echo

   if [ "$rip" = "f" ]; then
      $NICENESS mencoder -dvd $titleno -sws 2 -info name="$title" \
      -ovc lavc -lavcopts vcodec=mpeg4:vhq:vpass=1:vbitrate=$vbr \
      -vop crop=${autocrop},scale -zoom -xy 640 -ss 0:45 -endpos 1:00 -oac copy \
      -o /dev/null

      $NICENESS mencoder -dvd $titleno -sws 2 -info name="$title" \
      -ovc lavc -lavcopts vcodec=mpeg4:vhq:vqmin=2:vpass=2:vbitrate=$vbr \
      -vop crop=${autocrop},scale -zoom -xy 640 -ss 0:45 -endpos 1:00 -oac copy \
      -o /tmp/prev_$filename
   else
      $NICENESS mencoder -sws 2 -info name="$title" -ovc lavc \
      -lavcopts vcodec=mpeg4:vhq:vpass=1:vbitrate=$vbr \
      -vop crop=${autocrop},scale -zoom -xy 640 -ss 0:45 -endpos 1:00 -oac copy \
      -o /dev/null ${disc_title}.vob || err=y

      if [ "$err" = "y" ]; then
         err=

         #echo
         #echo "\$NICENESS: x${NICENESS}x"
         #echo "\$title:    x${title}x"
         #echo "\$vbitrate: x${vbr}x"
         #echo "\$autocrop: x${autocrop}x"
         #echo "\$disc_title: x${disc_title}x"

         echo
         read -n1 -p "i have seen there is an error... maybe we should C-c ?" next
      fi

      $NICENESS mencoder -sws 2 -info name="$title" -ovc lavc \
      -lavcopts vcodec=mpeg4:vhq:vpass=2:vbitrate=$vbr \
      -vop crop=${autocrop},scale -zoom -xy 640 -ss 0:45 -endpos 1:00 -oac copy \
      -o /tmp/prev_$filename ${disc_title}.vob || err=y

      if [ "$err" = "y" ]; then
         err=
         echo
         read -n1 -p "i have seen there is an error... maybe we should C-c ?" next
      fi
   fi

   if [ -e /tmp/prev_$filename ]; then
      if file /tmp/prev_$filename |grep -q RIFF
      then
         mplayer /tmp/prev_$filename
      fi
   fi

   echo

   read -n1 -p "did the preview play okay? [Y/n]: " prevok
   [ -n "$prevok" ] && echo

   if [ -n "$prevok" -a "$prevok" = "n" ]
   then
      echo
      echo "disc title was: $title"
      echo "video bit-rate was: $vbr"
      echo
      exit 1 
   fi
fi

echo

#############################################################################
#
# Encoding pass 2 (first video pass)
#
#############################################################################

err=

if [ "$rip" = "f" ]
then
   $NICENESS mencoder -dvd $titleno -sws 2 -info name="$title" \
   -ovc lavc -lavcopts vcodec=mpeg4:vhq:vpass=1:vbitrate=$vbr \
   -vop crop=${autocrop},scale -zoom -xy 640 -oac copy -o /dev/null || err=y
else
   $NICENESS mencoder -sws 2 -info name="$title" -ovc lavc \
   -lavcopts vcodec=mpeg4:vhq:vpass=1:vbitrate=$vbr \
   -vop crop=${autocrop},scale -zoom -xy 640 -oac copy -o /dev/null \
   "${disc_title}.vob" || err=y
fi

if [ "$err" = "y" ]; then
   read -n1 -p "i have seen there is an error... maybe we should C-c ?" next
fi

#############################################################################
#
# Encoding pass 3 (second video pass)
#
#############################################################################

err=

if [ "$rip" = "f" ]
then
   $NICENESS mencoder -dvd $titleno -sws 2 -info name="$title" \
   -ovc lavc -lavcopts vcodec=mpeg4:vhq:vpass=2:vbitrate=$vbr \
   -vop crop=${autocrop},scale -zoom -xy 640 -oac copy -o $filename || err=y
else
   $NICENESS mencoder -sws 2 -info name="$title" -ovc lavc \
   -lavcopts vcodec=mpeg4:vhq:vpass=2:vbitrate=$vbr \
   -vop crop=${autocrop},scale -zoom -xy 640 -oac copy -o $filename \
   "${disc_title}.vob" || err=y
fi

if [ "$err" = "y" ]; then
   read -n1 -p "i have seen there is an error... maybe we should C-c ?" next
fi

echo
read -n1 -p "shall i remove the log, VOB, and temp files? [y/N]: " clean

[ -n "$clean" ] && echo
[ "$clean" = "y" ] && cleanup

echo 
echo "Done.  Enjoy ;-)"
echo
