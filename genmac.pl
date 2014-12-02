#!/usr/bin/perl

#defined @ARGV ? ($if = $ARGV[0]) : ($if = "eth0");

@a = ('a'..'f');
@n = ( 0 .. 9 );

$mac = "00:"; # first octet

for ($i=0; $i<5; $i++)  # need five more
{
   foreach ("foo", "bar")
   {
      ((int rand 100) < 50)
         ? ($mac .= @a[int rand scalar @a])
         : ($mac .= @n[int rand scalar @n]);
   }
   $mac .= ":" if ($i < 4);
}
print "$mac\n";
