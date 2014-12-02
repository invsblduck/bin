#!/usr/bin/perl -w

die "you must supply path to RTF file.\n" if ! defined $ARGV[0]; 

$file = $ARGV[0];
die "$file does not exist.\n" if ! -f $file;

open HEADER, "head -1 $file |" or die "could not validate RTF file.\n";
$header = (<HEADER>);
close HEADER;

#die "$header\n"; 

die "$file does not seem to be an RTF file.\n" unless
   ($header =~ /^{\\rtf1\\ansi\\.*/);

open RTF, "< $file" or die "could not open RTF file.\n";
$chopping_header=2;
while (<RTF>)
{
   if ($chopping_header) { $chopping_header--; next; }
   s/$//;
   s/\\lang\d+\\f\d//g;
   s/\\b0|\\i0|\\ulnone//g;
   s/\\b|\\i|\\ul|\\par//g;
   s/\\tab/\t/g;
   print;
}
close RTF;
