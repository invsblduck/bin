#!/usr/bin/perl

BEGIN
{
   $0 =~ m#^(.*)[/\\]#;
   push @INC, $1;
};

use Getopt::Std;
use ParseRange qw(parse_range);

sub browse; 
sub scrape_page;
sub list_neohapsis;

$Getopt::Std::STANDARD_HELP_VERSION++;
$VERSION = "0.1";

#$firefox = "/home/brett/bin/firefox";
$firefox = "firefox-remote";
$useragent = "Mozilla/5.1 [en] (OpenBSD i386)";

getopts('npihu:a:l:s:d:o:');

if (defined $opt_a)  # archive to search
{
   $archive = $opt_a;
   #if ($archive =~ /netsys/i)
   if ($archive =~ /seclists/i)
   {
      #$netsys = 1;
      $seclists = 1;
      #$url = "http://lists.netsys.com/pipermail/full-disclosure/";
      $url = "http://seclists.org/lists/fulldisclosure/";
   }
   elsif ($archive =~ /netfilter/i)
   {
      $netfilter = 1;
      $url = "http://lists.netfilter.org/pipermail/netfilter/";
   }
   elsif ($archive =~ /neo/i)
   {
      $neohapsis = 1;
      $url = "http://archives.neohapsis.com/archives/";
   }
   else { die "'$archive' is an invalid archive.\n" };
}
else
{
   $archive = "full-disclosure";

   #$netsys = 1;
   #$url = "http://lists.netsys.com/pipermail/full-disclosure/";

   $seclists = 1;
   $url = "http://seclists.org/lists/fulldisclosure/";
}

# maybe accept user-supplied url?
#
defined $opt_u && ($url = $opt_u);
#defined $opt_u && (($url = $opt_u) =~ s#/$##);

# neohapsis archives
#
if (defined $neohapsis)
{
   &list_neohapsis if ($opt_p);     # show available archives

   $list = "bugtraq";                     # search bugtraq by default
   defined $opt_l && ($list = $opt_l);    #
   $url .= "$list/";                      #
}

# determine which date to use
#
if (defined $opt_d)
{
   $date = $opt_d;
   $url .= "$date/";
}
else
{
   # seclists / netfilter use different date formats in URLs ...

   #if ($netsys || $netfilter)
   if ($netfilter)
   {
      chomp ($year = `date +%G`);   #
      chomp ($month = `date +%B`);  # full name of month
      $date = "$year-$month";       #
   }
   elsif ($seclists)
   {
      chomp ($year = `date +%G`);   #
      chomp ($month = `date +%b`);  # abbr. name of month
      $date = "$year/$month";       #
   }
   else { $date = "current"; }
}

# show archive index if -i 
#
&browse ($url) if ($opt_i);

# automatically put current date into $url if it wasn't specified
#
($url .= "$date/") if (!defined $opt_d);
#($url .= "date.html") if ($netsys || $netfilter);  # sort posts by date
($url .= "date.html") if ($seclists || $netfilter);  # sort posts by date

# grab -s "search string" to search Subject: field
#
if (defined $opt_s)
{
   $subject = $opt_s;
   ($subject =~ /\|/)                     # handle grep-style alternates
      ? (@targets = split /\|/, $subject) #
      : ($targets[0] = $subject);         #
}

# otherwise browse whole archive page for $date and exit
#
else { &browse ($url); }

# now start scraping $url for any occurrences of $subject
#
$num_articles = 0;
$choice = '';
&scrape_page ($url);

if ($num_articles == 0) # no matches found :-(
{
   defined $list
      ? print "No postings to $list for $date/ match '$subject'.\n"
      : print "No postings to $archive for $date/ match '$subject'.\n";

   exit 0;
}

# grab selected reference URLs where $subject is found
#
foreach $num (@refnums) { push @urls, (grep /^\s*$num\.\shttp/, @refs); }

# erase lynx prefix (reference number) from the URL
#
foreach (@urls) { s/^\s*\d+\.\s//; chomp; }

# start printing results
#
defined $list
   ? print "Found $num_articles posting(s) to $list ($date/) ",
            "containing '$subject'\n"
   : print "Found $num_articles posting(s) to $archive ($date/) ",
            "containing '$subject'\n";

if (defined $opt_n)  # non-interactive mode
{
   #
   # TODO: put in checks for existing output files!
   #
   if (defined $opt_o && $opt_h) # HTMLize output
   {
      open HTML, "> $opt_o";
      select HTML;

      print "<html><head><title>";

      defined $list ? print $list : print $archive;
      print " ($date) results for '$subject'";

      print "</title></head><body bgcolor='black'><font color=white><h1>";
      defined $list ? print $list : print $archive;
      print " ($date) results for '$subject'</h1>";

      for ($i=0; $i<$num_articles; $i++)
      {
         $subs[$i] =~ s/&/&amp;/g;
         $subs[$i] =~ s/</&lt;/g;
         $subs[$i] =~ s/>/&gt;/g;
         $subs[$i] =~ s/\s/&nbsp;/g;
         print "<a href='$urls[$i]'>$subs[$i]</a><p>";
      }

      print "</font></body></html>";
      close HTML;
   }
   else  # no HTML output
   {
      if (defined $opt_o)  # redirect to file ?
      {
         open OUT, "> $opt_o";
         select OUT;
      }
      for ($i=0; $i<$num_articles; $i++) { print "$subs[$i] -> $urls[$i]\n\n"; }
      close OUT if (defined $opt_o);
   }
   exit 0;
}

# start interactive mode; show numbered results for user to select from
#
$cols = `tput cols`;
print "\n";

for ($i=0; $i<$num_articles; $i++)
{
   $offset = 0;
   undef @parts;

   if (length($subs[$i]) > ($cols - 8))   # 8 == (2 brackets + 6 spaces)
   {
      $size = ($cols - length($i) - 8);
      while ($offset < length($subs[$i]))
      {
         push @parts, substr($subs[$i], $offset, $size);
         $offset += $size;
      }
      print "[$i] ", (join "\n     ", @parts), "\n\n";
   }
   else
   {
      print "[$i] $subs[$i]\n\n";
   }
}

while ($choice !~ /^\s*q(uit)?|bye/i)
{
   if ($num_articles == 1) # there is only one result
   {
      print "Browse this post? [Y/n]: ";
      chomp ($choice = <STDIN>);
      &browse($urls[0]) if (($choice =~ /^\s*$/) || ($choice =~ /^\s*y/));
      exit 0;
   }

   print "\nEnter choice(s) [0-" . ($num_articles-1) . "] or 'all': ";
   chomp ($choice = <STDIN>);

   if ($choice =~ /^\s*\d.*\s*$/)
   {
      # check for accurate entry
      #
      if (($choice > ($num_articles-1)) || ($choice < 0))
      {
         print "(Bad selection)\n";
         next;
      }

      # accept a range of numbers and parse it
      #
      @choices = parse_range ($choice);

      # open up each choice in a new browser tab
      #
      foreach (@choices) { system "$firefox $urls[$_]"; }
   }
   elsif ($choice =~ /^\s*a(ll)?/i)  # browse every result
   {
      foreach (0 .. ($num_articles-1)) { system "$firefox $urls[$_]"; }
   }
}
# END main

sub browse
{
   system "$firefox \"$_[0]\"";
   exit 0;
}

sub scrape_page
{
   my $parsing_refs = 0;
   my $done;

   undef @subs;
   undef @refnums;
   undef @refs;

   open INDEX,
      "lynx -useragent='$useragent' -dump -dont_wrap_pre -width=256 '$url' 2>/dev/null|"
         or die "Unable to start lynx!: $!\n";
   
   die "$!\n" if ($? >> 8 > 0);

   while (<INDEX>)
   {
      chomp;
      next if /^$/;

      if ($parsing_refs)
      {
         push @refs, $_;
         next;
      }
      elsif (/^References$/)
      {
         $parsing_refs = 1;
      }
      else
      {
         $done = 0;
         foreach $search (@targets)
         {
            if (!$done)
            {
               if (/^\s*(\*|\+)\s\[(\d+)\](.*$search.*)$/i)
               {
                  $num_articles++;
                  push @refnums, $2;
                  push @subs, $3;
                  $done++;
               }
            }
         }
      }
   }
   close INDEX;
}

sub list_neohapsis
{
   print "Available lists, as of Wed Nov  3 16:32:05 PST 2004:\n";
   print "\nSecurity Threat Watch+    -         stw\n";
   print "Bugtraq                   -         bugtraq\n";
   print "NTBugtraq*                -         ntbugtraq\n";
   print "Win2KSecurity Advice*     -         win2ksecadvice\n";
   print "Vulnwatch*                -         vulnwatch\n";
   print "Vulndiscuss*              -         vulndiscuss\n";
   print "Full-Disclosure           -         fulldisclosure\n";
   print "\nSecunia Advisories*       -         secunia\n";
   print "SANS+                     -         sans\n";
   print "CERT*                     -         cert\n";
   print "RISKS Digest+             -         risks\n";
   print "\nSecurityFocus News*       -         sf/news\n";
   print "FOCUS-MS*                 -         sf/ms\n";
   print "FOCUS-IDS*                -         sf/ids\n";
   print "FOCUS-Sun*                -         sf/sun\n";
   print "FOCUS-Linux*              -         sf/linux\n";
   print "Pen-test                  -         sf/pentest\n";
   print "Secure Programming*       -         sf/secprog\n";
   print "WWW-Mobile-Code*          -         sf/www-mobile\n";
   print "Incidents                 -         incidents\n";
   print "Honeypots List*           -         sf/honeypots\n";
   print "Vuln-Dev*                 -         vuln-dev\n";
   print "Crypto (Various)*         -         crypto\n";
   print "ImmunitySec Daily Dave*   -         dailydave\n";
   print "\nFreshmeat Releases        -         apps/freshmeat\n";
   print "\nCisco Security Alerts*    -         cisco\n";
   print "NetBSD*                   -         netbsd\n";
   print "FreeBSD Security          -         freebsd\n";
   print "OpenBSD Security          -         openbsd\n";
   print "\nSnort IDS                 -         snort\n";
   print "Nessus Development*       -         nessus\n";
   print "NMAP-Hackers+             -         nmap\n";

   print "\n * Quarterly archive (you must specify -d YYYY-q[1234]).\n";
   print " + Yearly archive (you must specify -d YYYY).\n";
   exit 0;
}

sub HELP_MESSAGE
{
   $0 =~ s#.*/##g;
   print "\nusage: $0 [ -iph ] [ -a <archive> ] [ -l <list> ] ",
         "[ -s <subject> ] \n";
   print "             [ -d <date> ] [ -u <url> ] [ -o <file> ]\n";
   #print "\n   by default, browse full-disclosure\@lists.netsys.com\n\n";
   print "\n   by default, browse full-disclosure\@seclists.org\n\n";
   print "      -i                show archive index in browser\n";
   print "      -p                print available neohapsis lists (requires -a)\n";
   print "      -h                htmlize output (requires -o)\n";
   print "\n";
   exit 1;
}
