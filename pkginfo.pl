#!/usr/bin/perl 

#        A Perl script to work around dpkg(8) not being able to search for
#        multiple patterns at once (alternate patterns).

# Ported to FreeBSD! 

sub usage ;

$list = 0;
if (!@ARGV)
{ 
   system "pkg_info |less"; 
}
else
{
   foreach (@ARGV)
   {
      chomp;
      if (/^-/)
      {
         usage() if /^--?h(elp)?$/;

         if (/^--?l(ist)?$/)
         {
            $list = 1;
         }
         else
         {
            print "Removing leading '-'s from query string \"$_\"\n";
            s/^-+// ;
            push @a_regex, $_;
         }
      }
      else
      {
         push @a_regex, $_;
      }
   } 

   $pattern = join('|', @a_regex);

   $cmd = "pkg_info -a " .
         "|grep '^Information for ' " .
         "|awk '{ print \$3 }' " .
         "|cut -f1 -d: " .
         "|grep -iE '$pattern' >/tmp/$$.pkg_info";

   system "$cmd";

   if ($list)
   {
      open PKGLIST, "< /tmp/$$.pkg_info";
      while (<PKGLIST>)
      {
         chomp;

         #if (/deinstall/)
         #{
         #   $_ =~ s/\t+.*$//;
         #   print "package \'$_\' is currently deinstalled.\n";
         #   next;
         #}

         #$_ =~ s/\t+.*$//;
         #print "Files installed for \'$_\':\n";
         system ("pkg_info -L $_");
      }
      close PKGLIST;
   }
   else
   {
      system ("/bin/cat /tmp/$$.pkg_info");
   }
   unlink "/tmp/$$.pkg_info";
} 

sub usage
{
   print (   "\nGrep for names of installed FreeBSD packages.\n\n" .
               "usage:\n" . 
               "   $0 { -h | --help }\n" .
               "   $0 [ -l | --list ] { regex1 [ regex2 ... [ regexN ]] }\n" .
               "\nNo arguments will show an entire list of packages " .
               "using less(1).\n\n"
         );

   exit 1 ;
}
