#!/usr/bin/perl -W

use strict;
use warnings;

use XML::DOM;
use Devel::StackTrace;

my $parser = new XML::DOM::Parser;
my $doc = $parser->parse(\*STDIN);

my @uls = propDown($doc, ["ul"]); $#uls==0 or die "$!";

#print STDERR $uls[0]->getAttribute('class')."\n";

binmode(STDOUT, ':utf8');

my @list = tree2namelist($uls[0]);
for(@list){ print join(",",@$_)."\n"; }

exit(0);
my @country_list = grep{$_->getNodeType == ELEMENT_NODE}($uls[0]->getChildNodes);
scalar(@country_list)%2==0 or die join("\n","countries: li and ul should always be in pair: ".scalar(@country_list),join(' ',map{"'".$_->getNodeName."'"}@country_list),"$!");
for(my $i=0; $i<=$#country_list; $i+=2){
    
    print STDERR getText($country_list[$i])."\n";

    my ($country_name,@city_list) = getSubtypeList(@country_list[$i,$i+1]);
    print STDERR "$country_name\n";

    scalar(@city_list)%2==0 or die "cities: li and ul should always be in pair.\n $!";
    for(my $j=0; $j<=$#city_list; $j+=2){
	my ($city_name,@citypart_list) = getSubtypeList(@city_list[$j,$j+1]);
	print STDERR "$city_name\n";

	for my $citypart (@citypart_list){
	    my $citypart_name = getText($citypart);
	    print STDERR "$citypart_name\n";

	    print join(",",$citypart_name,$city_name,$country_name)."\n";
	}
    }
}
$doc->dispose;
exit(0);

sub getSubtypeList{
    my @nodes = @_;
    scalar(@nodes)==2 or die "$!";
    $nodes[0]->getNodeName eq "li" or die "$!";
    $nodes[1]->getNodeName eq "ul" or die "$!";

    my $name = getText($nodes[0]);
    $name =~ s/ //g;
    my @children = grep{$_->getNodeType == ELEMENT_NODE}$nodes[1]->getChildNodes;
    return ($name, @children);
}


sub tree2namelist{
    my ($root) = @_;

    my @nodes = grep{$_->getNodeType == ELEMENT_NODE}($root->getChildNodes);
    my @list = ();

    my $nodename = undef;
    my $hasChildren = 1;
    for my $node (@nodes){
	if($node->getNodeName eq "li"){
	    if(!$hasChildren){ push(@list, [$nodename]); }
	    $nodename = getText($node);
	    $nodename =~ s/,\s+/,/g;
	    $hasChildren = 0;
	    next;
	}
	elsif($node->getNodeName eq "ul"){
	    die $! unless defined($nodename);
	    $hasChildren = 1;
	    push(@list, map{[@$_,$nodename]}tree2namelist($node));
	}
	else{ die "$!"; }
    }
    if(!$hasChildren){ push(@list, [$nodename]); }
    die "$!" if scalar(@list)==0;
    return @list;
}

sub getText{
    my ($node) = @_;
    my @c = grep{$_->getNodeType ==TEXT_NODE}$node->getChildNodes;
    #$#c==0 or die join("\n",scalar(@c),$node,"$!")."\n";
    $#c==0 or die Devel::StackTrace->new()->as_string(); #join("\n",scalar(@c),$node,"$!")."\n";
    return $c[0]->getData;
}


sub propDown{
    my ($root, $tags) = @_;
    my $node = $root;
    my $n = scalar(@$tags);
    for(my $i=0; $i<$n; $i++){
	my $tag = $tags->[$i];
	my @c = $node->getElementsByTagName($tag,0);
	return @c if $i==$n-1;
	
	$#c==0 or die scalar(@c)." child(ren) for node '".$node->getNodeName."' with tag '".$tag."'\n";
	$node = $c[0];
    }
    die "Should not arrive here!";
}
