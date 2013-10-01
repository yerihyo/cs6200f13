#!/usr/bin/perl -W

use strict;
use warnings;

my %h = ();
my $wc = 0;

## count words
while(<STDIN>){
    chomp;
    my @F = split / /, $_;
    for(@F){ $wc++; $h{$_}++; }
}
my @l = sort{$h{$b}<=>$h{$a}}keys(%h);

## calc rank
my %r = ();
for(my $i=0; $i<@l; ){
    my $j = last_same_value_index(\%h,\@l,$i);
    for($i..$j){ $r{$l[$_]} = ($i+$j)/2+1; }
    $i=$j+1;
}

sub last_same_value_index{
    my ($h, $l, $i) = @_;
    for(my $j=$i+1; $j<scalar(@$l); $j++){
        return $j-1 if $h->{$l->[$j]} != $h->{$l->[$i]};
    }
    return scalar(@$l)-1;
}

## analyze counts
my $type_count_below5 = 0;
my $token_count_below5 = 0;
my $f_count = 0;
for(my $i=0; $i<@l; $i++){
    my $w = $l[$i];
    my $desc = [$h{$w}*$r{$w}, $w, $h{$w}, $r{$w}, $h{$w}/$wc];
    print join("\t", @$desc)."\n";

    if($i<25){ print STDERR join("\t", @$desc)."\n"; }

    if($f_count<25 && $w=~/^[fF]/){ 
        $f_count++;
        print STDERR join("\t", @$desc)."\n";
    }
    if( $h{$w}<5 ){
        $type_count_below5 += 1;
        $token_count_below5 += $h{$w};
    }
}

print STDERR "unique word count: ".scalar(@l)."\n";
print STDERR "word count: $wc\n";

print STDERR "below5 type count: $type_count_below5\n";
print STDERR "below5 token count: $token_count_below5\n";
