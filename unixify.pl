#!/usr/bin/perl

if (!defined @ARGV)
{
   print "--> 0x0d to proceed with all files... ";
   $continue = <STDIN>;

   $pipe = 0;
   print "\nConverting filenames ...\n\n";

   # grab all files except '.' and '..'
   #
   opendir FOO, "." or die "could not open current working directory ($!)\n";
   @files = grep ! /^\.+$/, readdir FOO;
   closedir FOO;
}
else
{
   if (($#ARGV == 0) && ($ARGV[0] eq "-"))
   {
      $pipe = 1;
      @files = <STDIN>;
   }
}

foreach (@files) {
   $old = $_;

   $_ =~ s#(\s|\+|\&)#_#g;  #change spaces,etc to underscores
   $_ =~ y/A-Z/a-z/;   #remove caps,brackets,parens,symbols,etc
   $_ =~ s#(\(|\)|\[|\]|\{|\}|\!|\@|\#|\$|\%|\^|\')##g; 
   $_ =~ s/_-_/-/g;    # remove crazy resulting creations
   $_ =~ s/__+/_/g;

   if ($old ne $_)
   {
      if ($pipe)
      {
         chomp;
         print "$_\n";
      }
      else
      {
         print "   $old -> $_\n";
         rename $old, $_  or print STDERR "Could not rename $old\n";
      }
   }
}

print "\nDone.\n\n" unless ($pipe);
