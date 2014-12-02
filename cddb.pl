#!/usr/bin/perl

# base url for freedb.org server
$freedb_url = "http://freedb.freedb.org/~cddb/cddb.cgi?cmd=cddb+query";

# use cd-discid(1) to grab cdrom info
open DISCID, "cd-discid /dev/cdrom |" or die "unable to open cd-discid(1)\n";
chomp ($discid = <DISCID>);
close DISCID;

# handle unrecognized output.......
die "I'm not sure what this is:\n$discid\n" if ($discid !~ /^\w+\s+\d+/);

# change space to plus (+)
$discid =~ s/\s/+/g;

# create url to request
$url = "${freedb_url}+${discid}&hello=user+hostname+program+version&proto=3";

# fetch it with lynx
open LYNX, "lynx -dump '$url' |"
   or die "could not request url ($url) with lynx.\n";
chomp ($cddb_info = <LYNX>);
close LYNX;

# prune out some categorical info
$cddb_info =~ s/^\d+\s\w+\s\w+\s//;

# grab the artist and album name
($artist, $album) = split ("/", $cddb_info);
$artist =~ s/\s*$//;
$album =~ s/^\s*//;

# print and exit
print "Artist: $artist\n";
print "Album: $album\n";

exit 0;
