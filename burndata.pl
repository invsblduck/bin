#!/usr/bin/perl -w

$cdrom = "/cdrom";
$diff_cmd = "/usr/bin/diff";

if (! @ARGV) { 
   print "\nusage: $0 { <file_1> [<file_2> ...] | <directory> }\n\n";
   exit 1; 
}

foreach (@ARGV) {
   if (! -e $_) {
      print "$_ does not exist.\n";
      $dirty=1;
   }
   else {
      push @files, $_;
   }
}

exit 1 if ($dirty);

# use RockRidge extensions (-r), long filenames (-l), Joliet extensions (-J) 
# [ and perhaps follow symlinks (-f) ? ] 
#
system ("sudo nice --18 mkisofs -r -l -J @files |sudo nice --18 cdrecord " .
         "-data -tao dev=0,0,0 speed=8 fs=8m gracetime=2 -") == 0
         or 
            die "\nCD-Recording failed.\n";

print "\nCD-Recording phase completed.\n";

# verify integrity of image
#
#print "\nCalculating original MD5 hash(es):\n\n";
#system ("md5sum @files");

print "\nVerifying disc image ...";

#if (($pid = fork()) != -1)
#{
#   if ($pid == 0)
#   {
      system "mount $cdrom" and die "Cannot mount CD-ROM!\n";
      $ok = 1;

      foreach (@files)
      {
         ($new = $_) =~ s#^.*/##g;
         $diff_cmd .= " -r" if ( -d $_ );

         if (system "$diff_cmd \"$_\" \"$cdrom/$new\"")
         {
            print STDERR "\n  -!!!- $cdrom/$new may differ from $_\n";
            $ok = 0;
         }
         else
         {
            print "." if $ok ;
         }
      }
      
      if ($ok)
      {
         print " ok\n";

         print "Remove original file(s) from disk? [y/N]: ";
         chomp ($rm = <STDIN>);

         if ($rm =~ /^\s*y(es)?\s*$/i)
         {
            unlink @files or print STDERR "unlink(): $!\n";
         }
      }
      print "\n";
      system "umount $cdrom";
      system "eject" if $ok ;
#   }
#   else
#   {
      # MAKE A SPINNER (progress meter) !
#   }
#}

