#!/usr/bin/perl -w

use File::Path;
use File::Basename;

sub getcmd;
sub run_lsdvd;
sub show;
sub rip;
sub encode;
sub play;
sub mount;
sub get_destdir;
sub get_yesno;
sub parse_range;
sub cleanup;
sub help;
sub quit;

$mount = "/cdrom";
$destdir = "/data/media/rip";

$lsdvdlog = "/tmp/lsdvd_$$.log";
$frameno_log = "/tmp/frameno.log";

$disc_title = "";


print "DVD command shell.\n";
while (1)
{
   print "command> ";
   &getcmd;
}

sub getcmd
{
   chomp (my $cmd = <STDIN>);
   return if ($cmd eq '');

   $_ = $cmd;

   if (/^\s*(h(elp)?|\?)(\s+.*)?$/i)
   {
      &help;
   }
   elsif (/^\s*i(nfo)?(\s+.*)?$/i)
   {
      &cleanup;
      &run_lsdvd;
   }
   elsif (/^\s*sh(ow)?(\s+.*)?$/i)
   {
      &show ($cmd);
   }
   elsif (/^\s*r(ip)?(\s+.*)?$/i)
   {
      &rip ($cmd);
   }
   elsif (/^\s*enc(ode)?(\s+.*)?$/i)
   {
      &encode ($cmd);
   }
   elsif (/^\s*p(lay)?(\s+.*)?$/i)
   {
      &play ($cmd);
   }
   elsif (/^\s*ej(ect)?(\s+.*)?$/i)
   {
      system "eject";
      print "Could not eject disc ($!).\n" if ($? >> 8 > 0);
   }
   elsif (/^\s*t(itle)?(\s+.*)?$/i)
   {
      $disc_title = $2;
      $disc_title =~ s/^\s*//;
      $disc_title =~ s/\s*$//;
   }
   elsif (/^\s*(bye|exit|q(uit)?)(\s+.*)?$/i)
   {
      &quit;
   }
   else
   {
      print "invalid command: $cmd\n";
   }
}

sub show
{
   (my $cmd = $_[0]) =~ s/^\s*sh(ow)?\s*//i;
   my ($num, $next);

   &run_lsdvd if ( ! -e $lsdvdlog );

   my @titles = &parse_range ($cmd);

   if (@titles)
   {
      open TMP, "> /tmp/dvdsh_$$";

      foreach $num (@titles)
      {
         $next = 0;

         open DVDINFO, "< $lsdvdlog"
            or ( print "Could not open lsdvd logfile '$lsdvdlog' ($!).\n"
                  && return 1 );

         while (<DVDINFO>)
         {
            if (/^Title:\ 0*$num/)
            {
               $next = 1;
               print TMP "\n$_";
               next;
            }
            if ($next)
            {
               last if (/^Title:/);
               s/^\t/\ \ \ / && print TMP "$_";
            }
         }
         close DVDINFO;
         print TMP "\n";

      } #end_foreach $num (@titles)

      close TMP;
      system "cat /tmp/dvdsh_$$ |ccze -A |less";
   }
   else # no titles supplied -- show info on all tracks
   {
      system "cat $lsdvdlog |ccze -A |less";
   }
}

sub rip
{
   (my $cmd = $_[0]) =~ s/^\s*r(ip)?\s*//i;

   my $nice = "/usr/bin/nice -+19";
   my @ripped_files;
   my ($arg,$dest,$val);

   if ($cmd !~ /^(\d|all)/i)
   {
      print "you must supply a number or range or 'all' as an argument.\n";
      return;
   }

   &run_lsdvd if ( ! -e $lsdvdlog );

   return if (($val = &mount) != 0);
   $dest = &get_destdir(".vob");

   print "nice +19 rip process? [Y/n]: ";
   ($nice = '') if ( ! ($val = &get_yesno(1)));

   my @titles = &parse_range ($cmd);

   foreach (@titles)
   {
      $vobfile = lc ($disc_title) . "$_-1";

      system ("$nice vobcopy -l -v -n $_ -o \"$dest\"");

      if ($? >> 8 > 0)
      {
         print "\n  -!!!- Couldn't rip track number $_ ($!)\n\n";
         print "files ripped:\n";

         my $lscmd = "ls --color=auto -lhF $dest/{" .
                     join (',', @ripped_files) . "}";

         system ("$lscmd");
         return;
      }
      push @ripped_files, "$dest/$vobfile";
   }

   system ("umount $mount");
   print "Could not unmount $mount\n" && return if ($? >> 8 > 0);

   return @ripped_files;
}

sub encode
{
   (my $cmd = $_[0]) =~ s/^\s*enc(ode)?\s*//i;

   my $ripvob;
   my $ripfly = "";
   my $target = "";
   my $audioid = 128;
   my $filename;
   my $dest;
   my @titles;

   my $nice = "/usr/bin/nice -+19";
   my $time_log = "/tmp/time_mencoder_$$.log";
   my $time_cmd = "/usr/bin/time --output=$time_log --append";

   my $val;

      #if ( -d "$destdir" )
      #{
      #   opendir MEDIA, "$destdir";
      #   @vobs = grep /.*\.vob$/i, readdir MEDIA;
      #   closedir MEDIA;

      #   if (@vobs)
      #   {
      #      print "\ni found in $destdir :\n";

      #      $i=1;
      #      foreach (@vobs)
      #      {
      #         print "  [$i] $_\n";
      #         $i++;
      #      }

      #      print "\nwould you like to encode any of these? [Y/n]: ";
      #      if (($val = &get_yesno(1)))
      #      {
      #      }

      #   }
      #}

   if (($cmd =~ /^\d+[-,]?\d*\s*/) || ($cmd =~ /^all\s*/i))
   {
      &run_lsdvd if ( ! -e $lsdvdlog );

      while ($ripfly !~ /^\s*(d(isk)?|f(ly)?)\s*$/i)
      {
         print "rip to (d)isk or on-(f)ly? [d/F]: ";
         chomp ($ripfly = <STDIN>);
         ($ripfly = "fly") if ($ripfly eq "");
      }

      $ripfly = 0 if ($ripfly =~ /^\s*d/i);

      if ($ripfly)
      {
         @titles = &parse_range ($cmd);
         $target = "-dvd";
      }
      else
      {
         @titles = &rip ($cmd);
      }
      $dest = &get_destdir(".avi");
   }
   elsif ($cmd =~ /^.+\.vob\s*$/i)
   {
      @titles = split /\s/, $cmd;
      foreach (@titles)
      {
         if ( ! -e $_ )
         {
            print "file '$_' does not exist.\n";
            return;
         }
      }
   }
   else
   {
      print "you must specify a dvd title range or .vob file name.\n";
      return;
   }

   if (@titles)
   {
      foreach (@titles)
      {
         if (/\.vob$/i)
         {
            $dest = dirname $_;
            ($disc_title = basename $_) =~ s/\.vob$//i;
            print "[output directory for .avi will be '$dest']\n";
         }

         print "output filename? [" . lc ($disc_title) . ".avi]: ";
         chomp ($filename = <STDIN>);

         ($filename = lc ($disc_title) . ".avi") if ($filename eq "");

         print "nice +19 mencoder process? [Y/n]: ";
         ($nice = '') if ( ! ($val = &get_yesno(1)));

         chdir $dest
           or
             print STDERR "\nWARNING: could not establish $dest as " .
                           "current working directory ($!).\n\n";
         #
         # rip audio  ( PHASE 1 )
         #

         $ENV{'TIME'} = "  [Elapsed time for audio encoding was %Es]\n" .
                        "  [Total processor usage was %P]\n" .
                        "  [Average total memory usage was %K kilobytes]\n" .
                        "  [Exit status: %x]\n";
         system (
                  "$nice $time_cmd mencoder -aid $audioid " .
                  "-ovc frameno -o frameno.avi -oac mp3lame " .
                  "-lameopts abr:br=128:q=3:vol=8 $target $_ |tee $frameno_log"
                );

         print "\nError encoding audio stream for $filename\n"
           && return if ($? >> 8 > 0);

         #
         # first video pass  ( PHASE 2 )
         #

         $ENV{'TIME'} =~ s/audio\ encoding/first video pass/;
         system (
                  "$nice $time_cmd mencoder -sws 2 -info name='$disc_title' " .
                  "-ovc lavc -lavcopts vcodec=mpeg4:vhq:vpass=1:vbitrate=875 ".
                  "-vop scale -zoom -xy 640 -oac copy -o /dev/null $target $_"
                );

         print "\nError encountered while encoding first video pass for " .
               "$filename :(\n" && return if ($? >> 8 > 0);

         #
         # second video pass  ( PHASE 3 )
         #

         $ENV{'TIME'} =~ s/first/second/;
         system (
                  "$nice $time_cmd mencoder -sws 2 -info name='$disc_title' " .
                  "-ovc lavc -lavcopts vcodec=mpeg4:vhq:vpass=2:vbitrate=875 ".
                  "-vop scale -zoom -xy 640 -oac copy -o $filename $target $_"
                );

         print "\nError encountered while encoding second video pass for " .
               "$filename :(\n" && return if ($? >> 8 > 0);

         print "\n";
         open TIME, "< $time_log"; print while (<TIME>); close TIME;
         unlink $time_log;

         push @encoded_files, "$dest/$filename";

      }#end_foreach (@titles)

      system ("ls --color=auto -lh $_ |sed 's/ \\+/  /g' |ccze -A")
        foreach (@encoded_files);

      print "\n";

   }#end_if (@titles)
   else
   {
      print "\n[nothing to encode]\n";
   }
}

sub play
{
   (my $cmd = $_[0]) =~ s/^\s*p(lay)?\s*//i;

   system "mplayer -dvd 1" && return if ($cmd eq "");

   my @titles = &parse_range ($cmd);

   if (@titles)
   {
      system "mplayer -dvd $_" foreach (@titles)
   }
   else
   {
      system "mplayer $cmd";
   }
   print "\n";
}

sub run_lsdvd
{
   my $gen_code;
   local $/;

   print "\n -> gathering DVD information ...";
   system ("lsdvd -x >| $lsdvdlog 2>/dev/null");

   if ($? == -1)
   {
      print "\nlsdvd needs to be installed and in your path.\n";
      return;
   }
   elsif ($? >> 8 > 0)
   {
      print "\nlsdvd did not work ($!).\n";
      return;
   }

   system ("lsdvd -p >| /tmp/lsdvd_$$.pl 2>/dev/null");  # generate perl script
   print "lsdvd could not generate perl code.\n" && return if ($? >> 8 > 0);

   open LSDVD_INFO, "< /tmp/lsdvd_$$.pl";

   $gen_code = <LSDVD_INFO>;
   eval $gen_code;

   close LSDVD_INFO;

   $disc_title = $lsdvd{'title'};
   my $aref_tracks = $lsdvd{'track'};
   my $longest_track = $lsdvd{'longest_track'};
   my $len_longest_track = $aref_tracks->[$longest_track-1]{'length'};
   $num_tracks = $#{$aref_tracks} + 1;

   # convert seconds into hours:minutes:seconds
   #
   my ($hrs,$min,$sec);

   $min = ($len_longest_track / 60);

   if ($min > 59)
   {
      ($hrs = $len_longest_track/60/60) =~ s/\.\d*//;
      $min = ($len_longest_track/60)%60; 
      $sec = $len_longest_track - ((($hrs*60)+$min)*60);
   }
   else
   {
      $hrs = 0;
      $min =~ s/\.\d*//;
      $sec = $len_longest_track % 60;
   }

   print "\n\n     * title is \'$disc_title\'\n";
   print "     * number of tracks is $num_tracks\n";
   print "     * longest is no. ($longest_track) @ [ $hrs:$min:$sec ]\n\n";
}

sub mount
{
   my $val;

   open MOUNTS, "< /proc/mounts";

   if (grep /cdrom/i, <MOUNTS>)
   {
      print "$mount already mounted. continue? [Y/n]: ";

      if ( ! ($val = &get_yesno(1)))
      {
         print "umount and eject? [y/N]: ";

         if (($val = &get_yesno(0)))
         {
            system ("umount $mount");
            print "Could not unmount $mount\n" && return(1) if ($? >> 8 > 0);
            system ("eject");
         }
         return(1);
      }
      return(0)
   }
   else
   {
      system ("mount $mount");
      print "Could not mount $mount\n" && return(1) if ($? >> 8 > 0);
   }
   close MOUNTS;
}

sub get_destdir
{
   my ($type) = @_;
   my ($dest,$val);

   while (1)
   {
      print "output directory for '$type' file(s)? [$destdir]: ";
      chomp ($dest = <STDIN>);

      ($dest = $destdir) if ($dest =~ /^\s*$/);

      if ( ! -d $dest )
      {
         if ( ! -e $dest )
         {
            print "$dest does not exist.\n";
            print "create? [Y/n]: ";

            if (($val = &get_yesno(1)))
            {
               mkpath $dest and last;
               print "Cannot create directory '$dest' ($!).\n";
            }
         }
         else
         {
            print "$dest exists and is NOT a directory.";
            system "ls --color=auto -lahF $dest";
         }
      }
      else
      {
         last;
      }
   }
   return $dest;
}

sub parse_range
{
   my ($range) = @_;
   my @titles;

   if ($range =~ /\d[-,]\d\s*$/)
   {
      my (@tmp1, @tmp2, @tmp3);

      if ($range =~ /,/)
      {
         @tmp1 = split (/,/, $range);
         foreach (@tmp1)
         {
            if (/-/)
            {
               @tmp2 = split /-/;

               if ($tmp2[0] < $tmp2[1])
               {
                  push @tmp3, ($tmp2[0] .. $tmp2[1]);
               }
               elsif ($tmp2[0] > $tmp2[1])
               {
                  push @tmp3, ($tmp2[1] .. $tmp2[0]);
               }
            }
            else
            {
               push @tmp3, $_;
            }
         }
      }
      else
      {
         @tmp2 = split /-/, $range;

         if ($tmp2[0] < $tmp2[1])
         {
            push @tmp3, ($tmp2[0] .. $tmp2[1]);
         }
         elsif ($tmp2[0] > $tmp2[1])
         {
            push @tmp3, ($tmp2[1] .. $tmp2[0]);
         }
      }

      @titles = sort { $a <=> $b } @tmp3;
   }
   elsif ($range =~ /^\s*(\d+)\s*$/)
   {
      $titles[0] = $1;
   }
   elsif ($range =~ /^\s*all\s*$/i)
   {
      @titles = (1..$num_tracks);
   }
   return @titles;
}

sub get_yesno
{
   my ($default) = @_;

   chomp (my $yesno = <STDIN>);

   if ($yesno =~ /^\s*$/)
   {
      $default ? return 1 : return 0 ;
   }

   ($yesno =~ /^\s*y\s*/i) ? return 1 : return 0 ;
}

sub help
{
   print "available commands:\n
  info                                      Show brief DVD information
  show   [ <range> ]                        Show detailed title information
  rip    <range> | all                      Rip title(s) to disk
  encode <range> | <file>                   Encode a VOB to DivX
  play   [ <range> | <file> | all ]         Play w/ Mplayer (-dvd 1 by default)
\n";
}

sub quit
{
   &cleanup;
   exit 0;
}

sub cleanup
{
   close MOUNTS;
   unlink ( $lsdvdlog,
            "/tmp/lsdvd_$$.pl",
            "/tmp/dvdsh_$$"
          );
}
