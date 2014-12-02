#!/bin/sh

x2vnc_dir=west

if [ -n "$DISPLAY" ]
then
   read -n1 -p "Open any VNC connections? [y/N]: " vnc

   case "$vnc" in
      y|y)
         echo
         ;;
      '')
         exit 0
         ;;
      [nN]|*)
         echo
         exit 0
         ;;
   esac

   while [ "$where" != "q" ]
   do 
      read -n1 -p "(T)yphon (C)yclops (A)ntlia (N)ewAntlia (X)2vnc or (Q)uit ? [x]: " where

      case "$where" in 
         '')
            x2vnc=1
            host="workstation-foo"
            ;;
         [tT]*)
            host="typhon"
            echo
            ;;
         [cC]*)
            host="cyclops"
            echo
            ;;
         [aA]*)
            host="antlia"
            echo
            ;;
         [nN]*)
            host="newantlia"
            echo
            ;;
         [xX]*)
            x2vnc=1
            host="workstation-foo"
            echo
            ;;
         *)
            echo
            echo [later]
            exit 1
         ;;
      esac

      [ -n "$x2vnc" ] && break
      nohup xvncviewer -passwd ~brett/.vnc/passwd $host >/dev/null 2>&1 &

   done

   nohup x2vnc -${x2vnc_dir} -resurface -passwdfile ~/.vnc/passwd ${host}:0.0 &
fi
