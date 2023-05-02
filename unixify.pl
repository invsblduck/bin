#!/usr/bin/perl -w

if (! @ARGV) {
    @files = <STDIN>;
}
else {
    @files = @ARGV
}

foreach (@files) {
    chomp;
    $_ =~ s/(\W)/_/g;  # change all non-word chars to underscores.
    $_ =~ s/_-_/-/g;   # remove crazy resulting creations.
    $_ =~ s/__+/_/g;   #

    print "$_\n";
}
