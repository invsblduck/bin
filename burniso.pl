#!/usr/bin/perl

sub usage;

&usage if ! defined @ARGV;
$numargs = @ARGV;

if ($numargs == 2)
{
   foreach (@ARGV)
   {
      (/^\s*((-f)|(--force))\s*$/)
         ? ($force = 1)
         : ($iso = $_);
   }
   &usage if ! $force;
}
elsif ($numargs == 1)
{
   $iso = $ARGV[0];
}
else
{
   &usage;
}

! -f $iso && die "$iso does not exist.\n";
-d $iso && die "$iso is a directory.\n";

open (FILE, "file $iso |");
while (<FILE>) { $ok=1, last if /ISO\s9660/ }
close FILE;

warn "$iso does not appear to be an ISO 9660 filesystem.\n" if ! $ok;
exit 0 if (!$ok && !$force);

system ("sudo nice --18 cdrecord -v -data -eject -dao " .
        "dev=0,0,0 speed=8 gracetime=2 $iso") == 0

         or 
            die "\nCD-Recording failed.\n";

print "\nCD-Recording phase completed.\n";

sub usage
{
   die "\nusage: $0 [-f|--force] <iso9660_file>\n\n";
}
