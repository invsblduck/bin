#!/usr/bin/perl

use File::Path;
use Getopt::Long;

sub usage;

$tracks = '';
$niceness = '';

Getopt::Long::Configure (qw/gnu_getopt/);
GetOptions ( 
            "h"         => \$help,
            "n"         => \$nice,
            "e"         => \$encode,
            "t=s"       => \$tracks,
            "a=s"       => \$artist,
            "c"         => \$cddb,
            "d=s"       => \$dir,
            "help"      => \$help,
            "nice"      => \$nice,
            "encode"    => \$encode,
            "tracks=s"  => \$tracks,
            "artist=s"  => \$artist,
            "cddb"      => \$cddb,
            "dir=s"     => \$dir
           );

# help message
&usage if $help;

# sanity checks
if (defined $cddb && defined $artist)
{
   print "[-] WARNING: --artist and --cddb parameters were both passed;\n";
   print "             CDDB information will override user-supplied artist.\n";
   print "\n";
}

if (defined $cddb)
{
   print "[*] attempting to retrieve CD information via freedb.org ....\n";

   # internet connectivity?
   system "~/bin/ichk -n >/dev/null 2>&1 ";
   if (($? >> 8) == 0)
   {
      # fetch CD info from freedb.org
      open CDDB, "~/bin/cddb.pl |"
         or
            ((defined $artist)
               ? (print "[-] could not execute cddb.pl script ($!)\n")
               : (die "[-] could not execute cddb.pl script ($!)\n"));

      @infos = (<CDDB>);
      close CDDB;

      if (defined @infos)
      {
         print "[+] Successful.\n";
         foreach (@infos)
         {
            chomp;
            print "\t$_\n";
            # remove Artist: and Album: labels
            s/^(\w+):\s//;
            # remove quotes
            s/('|")//g;

            # dirty and disgusting bidirectional hack... screw open2()
            open UNIXIFY, "echo -n '$_' | ~/bin/unixify.pl - |"
               or print "\n[-] unable to open unixify.pl ($!)\n";
            chomp ($_ = <UNIXIFY>);
            close UNIXIFY;
         }
         # this is the string we'll use to rename tracks
         $artist = join '-', @infos;

         # try to suggest a directory derived from album name
         if (!defined $dir || (defined $dir && $dir !~ /$infos[1]/i))
         {
            print "[+] rip tracks into a subdirectory named '$infos[1]' ? [n] ";
            chomp ($ans = <STDIN>);

            unless (($ans =~ /^\s*$/) || ($ans !~ /^y/i))
            {
               if (defined $dir)
               {
                  chop $dir if ($dir =~ m#/$#);
                  $dir .= "/$infos[1]";
               }
               else { $dir = $infos[1] }
            }
         }
      }#if cddb fetch worked
      else
      {
         print "[-] could not obtain CDDB information\n";
         if (defined $artist)
         {
            print "[*] falling back to user-supplied artist string\n";
         }
         else
         {
            print "[-] track names will remain generic\n";
         }
      }
   }#if connected to internet
   else
   {
      print "[-] internet connection failed; ";
      print "CDDB information will be unavailable\n";
      if (defined $artist)
      {
         print "[*] falling back to user-supplied artist string\n";
      }
      else
      {
         print "[-] track names will remain generic\n";
      }
   }
}#if $cddb

# figure out target directory 
if (! defined $dir)
{
   print "[*] tracks are being ripped to current directory.\n";
}
else
{
   if ( ! -e $dir )
   {
      print "[-] '$dir' does not exist. Create? [y] ";
      chomp ($ans = <STDIN>);

      if (($ans =~ /^\s*$/) || ($ans =~ /^y/i))
      {
         mkpath $dir or die "[-] cannot create '$dir' ($!)\n";
      }
      else
      {
         print "[-] exiting.\n"; 
         exit 1;
      }

   }
   elsif ( ! -d $dir )
   {
      print "[-] '$dir' exists and is not a directory!\n";
      exit 1;
   }
   chdir $dir;
}

($niceness = "nice -+19") if $nice;

# rip the tracks!
print "\n[*] ripping .WAVs to disk ...\n\n";
system ("sudo $niceness cdparanoia -v -B -z=1 $tracks");
die "\n[-] exiting\n" if ($? >> 8 > 1);

# eject disc
system ("eject");

# rename files
if ($artist)
{
   print "[*] renaming files...\n";

   opendir DIR, ".";
   @files = grep /^track\d+\.cdda\.wav$/, readdir DIR;
   closedir DIR;

   foreach $old (@files)
   {
      $new = "$artist-" . $old;
      rename $old, $new;
      (push @newfiles, $new) if $encode;
   }
}

if ($encode)
{
   chomp ($user = `whoami`);
   $group = "users";

   # load tracks into an array if we haven't already
   if (! defined @newfiles)
   {
      opendir DIR, ".";
      @newfiles = grep /^track\d+\.cdda\.wav$/, readdir DIR;
      closedir DIR;
   }

   print "[*] encoding to MP3 ...\n\n";

   foreach $wav (@newfiles)
   {
      # encode wav to mp3
      ($mp3 = $wav) =~ s/\.cdda\.wav$/\.mp3/;
      system ("sudo $niceness lame -h --vbr-new -V2 '$wav' '$mp3'");

      # see if it worked...
      ($? >> 8 > 0) ? ($keep=1) : ($keep=0);

      # change ownership
      system ("sudo chown ${user}:${group} '$mp3'");

      unless ($keep)
      {  # unlink accordingly
         unlink $wav or print STDERR "\n[-] could not remove '$wav' ($!)\n";
      }
   }
}

print "\n[*] Done.\n\n";

sub usage
{
   print STDOUT "usage: $0 [-e|--encode] [-n|--nice]\n",
                "       [-t <range>|--tracks <range>] ", 
                " [-a <artist>|--artist <artist>]\n",
                "       [-c|--cddb] [-d <directory>|--dir <directory>]\n";
   exit 1;
}
