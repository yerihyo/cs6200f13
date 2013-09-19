#!/usr/bin/perl -W

use strict;
use warnings;

my %h = ();
my $wc = 0;
while(my $l=<STDIN>){
    chomp($l);
    #print STDERR "$l\n";
    $wc++;
    $h{$l}++;
    print join(",",log(scalar(keys(%h))), log($wc) )."\n";
}
