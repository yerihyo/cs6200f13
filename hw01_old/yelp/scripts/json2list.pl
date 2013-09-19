#!/usr/bin/perl -W

use strict;
use warnings;
use Getopt::Std;
use JSON qw /encode_json decode_json/;
use Data::Dumper;
use File::Path qw /make_path/;

binmode(STDERR, ':utf8');

my %opts = ();
getopts('O:', \%opts);

for(qw/O/){ defined($opts{$_}) or die "usage: $0 -O <OUT_DIR>"; } # -l <location> -p <page>"; }

my $s=join("\n",map{chomp; $_;}(<STDIN>));
my $json_tree = decode_json($s);
#my @locs = split /,/, $opts{l};

my $businesses = $json_tree->{"businesses"};
for my $b (@$businesses){
    my $id = $b->{"id"};
    my $rating = $b->{"rating"};
    #my $OUT_DIR = join("/",$opts{O},reverse(@locs),$opts{p});
    my $OUT_DIR = $opts{O};
    #make_path($OUT_DIR);
    my $ofile = join("/",$OUT_DIR,"$id.json.gz");
    if(-e $ofile){ next; }

    print STDERR "===== Working on business '$id' =====\n";
    str2file($ofile, encode_json($b), "| python -m json.tool | gzip -c");
}
#print STDERR scalar(@$businesses); exit(0);

#print Dumper $businesses; exit(0);
print join("\n",scalar(@$businesses), $json_tree->{"total"})."\n";

exit(0);

sub str2file{
    my ($filename, $str, $cmd) = @_;
    my $p = (defined($cmd)?"$cmd":"");
    open FILE, "$p >$filename" or die "$!";
    print FILE "$str\n";
    close(FILE);
}
