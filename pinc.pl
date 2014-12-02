#!/usr/bin/perl

if (@ARGV)
{
   foreach (@ARGV)
   {
      if (m/^\s*--?l(ist)?\s*$/)
      {
         foreach(@INC)
         {
            if ( ! m/^\.$/)
            {
               print "$_:\n";
               system "ls -G $_";
               print "\n";
            }
         }
      }
      elsif (m/^\s*--?h(elp)?\s*$/)
      {
         &usage;
      }
      else
      {
         &usage;
      }
   }
}
else
{
   foreach(@INC)
   {
      print "$_\n";
   }
}

sub usage
{
   print "\nusage: $0 [-l|--list] [-h|--help]\n";
   exit 0;
}
