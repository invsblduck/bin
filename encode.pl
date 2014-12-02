#!/usr/bin/perl

opendir DIR, ".";
@files = grep /.*\.wav/i, readdir DIR;
closedir DIR;

print "\nEncoding to MP3 ...\n\n";

foreach (@files) {
   $old = $_;
   $_ =~ s/\.cdda\.wav$/\.mp3/i ;
   system ("nice -+19 lame -h -V2 $old $_");
   unlink $old or print STDERR "\n-!!!- Could not remove $old: $!\n";
}

print "\nDone.\n\n";
