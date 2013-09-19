#!/usr/bin/perl -W

use strict;
use warnings;

my %h = ();
my $wc = 0;
while(<STDIN>){
    chomp;
    my @F = split / /, $_;
    for(@F){ $wc++; $h{$_}++; }
}
my @l = sort{$h{$b}<=>$h{$a}}keys(%h);

my $type_count_below5 = 0;
my $token_count_below5 = 0;
my $f_count = 0;
for(my $i=0; $i<@l; $i++){
    my $w = $l[$i];
    if($i<5){ print join(" ", $w, $h{$w}/$wc)."\n"; }

    if($f_count<5 && $w=~/^[fF]/){ 
        $f_count++;
        print join(" ", $w, $h{$w})."\n";
    }
    if( $h{$w}<5 ){
        $type_count_below5 += 1;
        $token_count_below5 += $h{$w};
    }
}

print "unique word count: ".scalar(@l)."\n";
print "word count: $wc\n";

print "below5 type count: $type_count_below5\n";
print "below5 token count: $token_count_below5\n";
