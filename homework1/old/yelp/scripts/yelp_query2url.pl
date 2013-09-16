#!/usr/bin/perl

use strict;
use warnings;

use Getopt::Std;
use URI::Escape;
use Net::OAuth;

$Net::OAuth::PROTOCOL_VERSION = Net::OAuth::PROTOCOL_VERSION_1_0;

my %opts = ();
getopts('c:C:t:T:q:p:', \%opts);

for(qw/c C t T q p/){
    defined $opts{$_} or die "usage: $0 -c <consumer_key> -C <consumer_secret> -t <token> -T <token_secret> -l <location> -p <api_type>\n"; }

#print STDERR $opts{q}."\n"; exit(0);

my $query = $opts{q};
my $url_header = "http://api.yelp.com/v2/".$opts{p};
#print STDERR "$url_header\n"; exit(0);

my $request = Net::OAuth->request('protected resource')->new(
    consumer_key => $opts{c},
    consumer_secret => $opts{C},
    token => $opts{t},
    token_secret => $opts{T},
    request_url => "$url_header?$query",
    request_method => 'GET',
    signature_method => 'HMAC-SHA1',
    timestamp => time,
    nonce => nonce(),
    );
$request->sign;
print $request->to_url."\n";
exit(0);

sub nonce {
  my @a = ('A'..'Z', 'a'..'z', 0..9);
  return join("",map{ $a[rand(scalar(@a))] }(0..31));
}
