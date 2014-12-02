#!/usr/bin/perl
# written by Brett Campbell

use LWP::UserAgent;
use HTTP::Request::Common;
use Getopt::Std;

sub post;

%contacts   =  ( 
                  bob  => '555-555-1212',
                  fred => '555-123-4567'
               );

$host = "www.css.vtext.com";
$base_url = "http://$host/customer_site/jsp";

my $cookie = "JSESSIONID=d0305c700c7e\$5E\$3F\$3; timeZoneOffset=480";
my $accept = 'text/xml,application/xml,application/xhtml+xml,text/html;' .
               'q=0.9,text/plain;q=0.8,image/png,image/jpeg,image/gif;' .
               'q=0.2,*/*;q=0.1';

my @headers = (
               'Host' => 'www.vtext.com',
               'User-Agent' => 'Perl test hack (Linux i686)',
               'Accept' => $accept,
               'Accept-Encoding' => 'gzip,deflate',
               'Accept-Language' => 'en-us,en;q=0.5',
               'Accept-Charset' => 'us-ascii,ISO-8859-1,utf-8;q=0.7,*;q=0.7',
               'Keep-Alive' => '300',
               'Connection' => 'Keep-Alive',
               'Cookie' => $cookie,
               'Content-Type' => 'application/x-www-form-urlencoded'
              );

getopts ('t:r:c:s:d:w:ifubp');

if ( $opt_p )
{
   foreach $key ( sort(keys %contacts) )
   {
      printf('  %-14s', $key); 
      print "=>  $contacts{$key}\n";
   }
   exit 0;
}

if ( $opt_i )
{
   print "to (ph.#): ";
   chomp ($min = <STDIN>);

   print "from (email): ";
   chomp ($sender = <STDIN>);

   print "callback (ph.#): ";
   chomp ($cb = <STDIN>);

   print "subj: ";
   chomp ($subj = <STDIN>);

   print "urgent? ";
   chomp ($urg = <STDIN>);

   $urg =~ /^\s*(1|y(es)?|t(rue)?)/i
      ? $urg = 1
      : $urg = 0;
}
else # non-interactive
{
   die "supply receiver MIN with '-t'\n" unless defined $opt_t;
   $rcpt = $opt_t;

   if ( defined $contacts{$rcpt} ) { $rcpt = $contacts{$rcpt} }
   else { die "unknown recipient: '$rcpt'\n" if ( $rcpt =~ /[a-z]/i ) }

   ($min = $rcpt) =~ s/[-_\(\)\. ]//g;

   die "bad telephone number: $rcpt\n" if ( length $min != 10 );

   $urg    = $opt_u || 0;
   $sender = $opt_r || '5555555555@vtext.com';

   $cb   = $opt_c  if defined $opt_c;
   $subj = $opt_s  if defined $opt_s;
   $wait = $opt_w  if defined $opt_w;
}

if ( defined $opt_d )
{
   local $/;

   if ($opt_d =~ /^\s*-\s*$/)
   {
      $txt = <STDIN>;
      close STDIN;
   }
   else
   {
      die "invalid file: \"$opt_d\"\n" unless ( -e $opt_d && -f $opt_d );
      open TXT, "< $opt_d" or die "could not open \"$opt_d\": $!\n";
      $txt = <TXT>;
      close TXT;
   }
}
else
{
   local $/;
   print "(reading data until eof):\n";
   $txt = <STDIN>;
   close STDIN;
   print "\n";
}

if ( defined $subj )
{
   my $sublen = length ($subj);
   if ( $sublen > 20 && ! defined $opt_f )
   {
      # we already closed STDIN so..... hack
      open STDIN, "< /dev/tty" or die "can't open /dev/tty for STDIN: $!\n";
      print "subject exceeds 20 bytes. proceed with $sublen bytes? ";
      die "aborted.\n" unless ( ($cont=<STDIN>) =~ /^\s*(1|y)/i );
   }
   $len = length ($txt) + $sublen;
}
else { $len = length ($txt) }

if ( $len > 160 )   # SMS max payload
{
   if ( ! $opt_f )
   {
      open STDIN, "< /dev/tty" or die "can't open /dev/tty for STDIN: $!\n";
      print "data exceeds SMS max payload. proceed with $len bytes? ";
      die "aborted.\n" unless ( ($cont=<STDIN>) =~ /^\s*(1|y)/i );
   }

   $mod = int ( $len % 160 );
   $num_chunks = int ( $len / 160 );

   defined $subj
      ? ($chunk_size = ( 160 - length $subj ))
      : ($chunk_size = 160);

   for ($i = 0; $i < $num_chunks; $i++)
   {
      push @chunks, substr ($txt, 0, $chunk_size);
      substr ($txt, 0, $chunk_size) = "";
   }
}

%args = (
         trackResponses => 'No',
         Send.x         => 'Yes',
         showgroup      => 'n',
         DOMAIN_NAME    => "\%40vtext.com",
         min            => $min,
         subject        => $subj,
         sender         => $sender,
         type           => $urg,
         callback       => $cb,
      );

if ( defined @chunks )
{
   $i = 1;
   if ( $opt_b )
   {
      print "sending sms text chunk #$i of ", ($num_chunks+1), " ... ";
      $i++;

      $args{'text'} = $txt;
      post (\%args, @headers);

      @chunks = reverse @chunks;
      print "\n";
   }

   foreach ( @chunks  )
   {
      print "sending sms text chunk #$i of ", ($num_chunks+1), " ... ";
      $i++;

      $args{'text'} = $_;
      post (\%args, @headers);

      print "\n";
      sleep $wait if defined $wait;
   }

   if ( ! $opt_b )
   {
      print "sending sms text chunk #$i of ", ($num_chunks+1), " ... ";
      $args{'text'} = $txt;
      post (\%args, @headers);
   }
   print "\nwrote $len bytes.";
}
else
{
   print "sending sms text ($len bytes)... ";
   $args{'text'} = $txt;
   post (\%args, @headers);
}
print "\n";

# 
# END MAIN
#

sub post
{
   my $r_args = shift;
   my @hdrs = @_;

   my $agent = LWP::UserAgent->new;
   my $response = $agent->request ( POST "$base_url/messaging_lo.jsp",
                                    $r_args,
                                    @hdrs
                                 );
   $response->is_success
      ? print $response->status_line
      : die "\n\n\tPOST failed. Server returned ",
                                    $response->status_line, "\n";

   delete $r_args->{'Send.x'};
   delete $r_args->{'showgroup'};
   $r_args->{'disclaimer_submit.x'} = 25;
   $r_args->{'disclaimer_submit.y'} = 15;
            
   $response = $agent->request ( POST "$base_url/disclaimer.jsp",
                                 $r_args,
                                 @hdrs
                              );
   $response->is_success
      ? print ", ", $response->status_line
      : die "\n\n\tPOST failed. Server returned ",
                                 $response->{'status_line'}, "\n";
}
# http://www-mtl.mit.edu/~kush/PERL5_UNLEASHED/index.htm
