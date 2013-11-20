#!/usr/bin/perl -W

use strict;
use warnings;
use Getopt::Std;

my %opts = ();
getopts('k:h:d:D:v', \%opts);

for(qw/h/){ defined($_) or die "usage: $0 -h <dict> [-v] [-d <delim_in>] [-D <delim_out>] [-k <key_index>] [-H <delim_dict>] [-K <key_dict>]"; }

my $k = (defined($opts{k})?($opts{k}-1):0);
my $k_dict = (defined($opts{K})?($opts{K}-1):0);
my $delim_in = (defined($opts{d})?$opts{d}:'\s+');
my $delim_out = (defined($opts{D})?$opts{D}:(defined($opts{d})?$opts{d}:' ') );
my $delim_dict = (defined($opts{H})?$opts{H}:'\t');

my $h = file2hash($opts{h},$delim_dict,$k_dict);

#print STDERR scalar(keys(%$h))."\n";
#my @keys = keys(%$h);
#print STDERR $keys[0]."\n";
#exit(0);
sub file2hash{
    my ($filename, $d,$k) = @_;
    my %h = ();
    open FILE, "<", $filename or die "$!";
    while(<FILE>){
        chomp;
        my @F = split /$d/, $_;
        $h{$F[$k]} = 1;
    }
    close(FILE);
    return \%h;
}

while(<STDIN>){
    chomp;
    my @F = split /$delim_in/, $_;
    next if defined($opts{v}) == defined($h->{$F[$k]});

    print join("$delim_out",@F)."\n";
}

exit(0);
