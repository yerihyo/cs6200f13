#!/usr/bin/perl -W

use strict;
use warnings;

my %h = ();
my $wc = 0;
while(my $l=<STDIN>){
    chomp($l);
    $wc++;
    $h{$l}++;
    print join(",",length(keys($h)), $wc)."\n";
}
