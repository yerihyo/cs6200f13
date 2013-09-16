#!/usr/bin/perl -W

use strict;
use autodie qw/:all/;
use warnings;
use Getopt::Std;
use Benchmark;

use WWW::Mechanize;
use HTML::TreeBuilder;
use HTML::AsText::Fix;
use Lingua::Identify qw(:language_identification);
use File::Basename;
use File::Path qw(make_path);

use threads;
use threads::shared;
use Thread::Semaphore;

#use constant OFILE_CONTENTS => "contents.tar.gz";
#use constant OFILE_LINKS => "links.list";
use constant WAIT_THRESHOLD => 20;

my %opts = ();
getopts('i:l:O:m:t:n:', \%opts);

for(qw/i l O m t n/){ defined($opts{$_}) or die "usage: $0 -i <input_url> -l <language> -O <OUT_DIR> -m <memory in MB> -t <threads_folder_name> -n <max_pages_count>\n"; }
my $thread_max = int($opts{m}/40);
print STDERR "========= THREAD MAX: $thread_max =========\n";
my $sem_threads = Thread::Semaphore->new( $thread_max );


####################################################
# OUTPUT FORMAT & LOGIC
#
# - checks if symlink /raw/URL_PATH exists
# - if not exists create thread
#  * process dumps result to /threads/[tid]/
#  * <LOCK>
#  * checks if symlink /raw/URL_PATH exists
#  * link -s /threads/[tid] /raw/URLPATH
#  * link -s /threads/[tid] /W/[w]++
#  * <UNLOCK>
####################################################

my $r :shared = 0;
my $w :shared = 0;

#my @threads = ();
#my %thread_info = ();
#my @prev_thread_counts = ();


#my $url_confs = [file2lines("<".$opts{i})];
my $url_confs = [$opts{i}]; # quick n dirty change - file version to direct input version

make_path($opts{O}."/W/"); # or die "$!";

my @history=(0);
while(1){
    #@threads = clean_threads($sem_threads, \@threads);
    #clean_threads($sem_threads, \%thread_info);
    clean_threads($sem_threads, $history[0]);
    my @threads = threads->list();
    my $thread_count = scalar(@threads);
    print STDERR "============== THREAD #$thread_count r:$r w:$w n:".$opts{n}." =================\n";
    push(@history, $threads[$#threads]->tid()) if @threads;
    while($#history>=3){ shift @history; }
    #print STDERR "\n\n".("=" x 30)."thread #: $thread_count\n\n\n";
    
    if( isQueueEmpty($r,$w,scalar(@$url_confs), $opts{n}) ){ # empty queue
	last if $thread_count==0;# no thread running 

	if($history[0]>=100){ # if enough data
	    if($history[0]-$history[$#history]<=(5*$#history)){
		print STDERR "Small number of pages remaining with empty queue! Exitting!\n";
		exit(0);
	    }
	}
	    
	print STDERR "Waiting for $thread_count thread(s)\n"; sleep 2; next; # running thread exists
    }
    
    # non-empty queue
    while( !isQueueEmpty($r,$w,scalar(@$url_confs), $opts{n}) ){
	if(! $sem_threads->down_nb()){ sleep 2; last; } # no semaphore
	my $line;
	($line,$url_confs) = readLine($opts{O}."/W/%d/%d/links.list", \$r,\$w,$url_confs);
	#print STDERR join("\n",join(" ",@$url_confs), $r,$w, $opts{O}."/W/".($r+1)."/links.list\n")."\n";
	if(!defined($line) or $line=~/^\s*$/){ $sem_threads->up(); next; }

	my @F = split /\s+/, $line; $#F==2 or die "Illegal url conf line";
	my ($name, $url, $BASE_URL) = @F;

	my $RAW_DIR = url2filepath($url, $BASE_URL, $opts{O}."/raw");
	if (-d $RAW_DIR){ $sem_threads->up(); next; }

	my $thr = threads->create(\&parseURL, $name, $url, $BASE_URL, $opts{O}, $opts{t});
	my $tid = $thr->tid();

	#my $tt = create_thread($name, $url, $BASE_URL, $opts{O});
	#$thread_info{$tt->[0]} = $tt->[1];
	#push(@threads, $thr);
    }
}

print STDERR "EXIT PROGRAM NORMALLY\n";
exit(0);

sub url2filepath{
    my ($url,$BASE_URL,$BASE_DIR) = @_;
    my $path = $url;
    $path=~s/^$BASE_URL\/?//;
    $path=~s/^(\.\/)+//;
    $path=~s/^(\.\.\/)+//;
    $path=~s/\&/_/g; 
    return "$BASE_DIR".(($path=~/^\s*$/)?(""):("/$path"));
}

sub isQueueEmpty{
    my ($r,$w,$lines_count, $max_pages_count) = @_;
    return ($w>=$max_pages_count or ($r==$w and $lines_count==0) );
}

sub parseURL{
    my ($name, $url,$BASE_URL, $BASE_DIR, $thread_folder_name) = @_;
    my $tid = threads->tid();
    print STDERR "++++++++ [START] ('$tid') $url\n";

    my $MY_DIR = join("/",$BASE_DIR,$thread_folder_name,int($tid/1000),$tid);
    if(-d $MY_DIR){ print STDERR "Folder for thread already exists?!"; exit(1); }


    my @ofilenames = qw/contents.txt links.list/;

    $SIG{'KILL'} = sub {
	threads->exit();
    };

    my $RAW_DIR = url2filepath($url, $BASE_URL, "$BASE_DIR/raw");
    if(-d $RAW_DIR){
	lock($w);
	my $t_file = readlink( join("/",$RAW_DIR,$ofilenames[0]) );

	my @F = split '/', $t_file;
	if ($thread_folder_name eq $F[$#F-3]){ return; } # already processed by current run

	++$w;
	my $T_DIR = dirname($t_file);
	my $W_DIR = "$BASE_DIR/W/".int($w/1000)."/$w";
	if(-d $W_DIR){ print STDERR "Something wrong with lock\n"; exit(1); }
	link_files($T_DIR,$W_DIR,@ofilenames);
	return;
    }

    make_path($MY_DIR); # or die "Cannot create path '$MY_DIR'\n";

    my ($text,@all_links) = getLinkedText($url);
    my @links = grep{/^$BASE_URL/}@all_links;
    my $language = (defined($text)?langof($text):undef);
    lines2file("$MY_DIR/".$ofilenames[1], map{join("\t",$name,$_,$BASE_URL)}@links);

    if( (!defined($text)) or (length($text)>200 and $language ne $opts{l}) ){ $text = ""; }
    else{ $text =~s/\s+/ /g; }
    #$sem_threads->up(); return; }


    my $ofile = "$MY_DIR/".$ofilenames[0];
    open FILE, ">", $ofile or (print STDERR join("\n","('$tid') Cannot open ofile '$ofile'",$!)."\n" and exit(1));
    binmode(FILE, ":utf8");
    print FILE "$text\n";
    close(FILE);
    print STDERR "-------- [DONE] <$language> ('$tid') $url >>> $ofile (queue-size:".($w-$r).")\n";

    {
	lock($w);
	if(-d $RAW_DIR){ return; }
	++$w;
	my $W_DIR = "$BASE_DIR/W/".int($w/1000)."/$w";
	link_files($MY_DIR,$RAW_DIR,@ofilenames);
	link_files($MY_DIR,$W_DIR,@ofilenames);
    }

    #$sem_threads->up();
}

sub link_files{
    my ($from, $to, @filenames) = @_;
    print STDERR "linking '$from' to '$to'\n";
    if(-d $to){ print STDERR "Something wrong with lock\n"; exit(1); }
    make_path($to);

    for(@filenames){
	symlink("$from/$_", "$to/$_") or (print STDERR join("\n",join(" ",$from,$to),"$!")."\n" && exit(1));
    }
}

#sub create_thread{
#    my ($name, $url, $BASE_URL, $BASE_DIR) = @_;

#    my $thr = threads->create(\&parseURL, $name, $url, $BASE_URL, $BASE_DIR,time());
    #$thr->detach();
    #$threads_info->{$thr} = time();
#    print STDERR "++++++++ [START] (#$i) $url\n";
    #$thr->{"time"} = time();
    #return [$thr->tid(),time()];
#}

sub clean_threads{
    #my ($sem_threads, $threads) = @_;
    my ($sem_threads, $thres) = @_;

    my $now = time();
    #my @clean = ();

    my @threads = threads->list();
    for my $thr (@threads){ #@$threads){
	#my $age = $now - $tt->[1];
	#my $age = $now - ($thread_info->{$thr->tid()});
	#my $age = $now - ($thr->{time});
	#my $age = 0;
	my $tid = $thr->tid();

	if( !($thr->is_running()) ){
	    $thr->join;
	    print STDERR "[------EEEEEEEEEEEEnding thread] '$tid' (queue-size:".($w-$r).")\n";
	    $sem_threads->up();
	}
	elsif($tid<=$thres){
	    print STDERR "[------KKKKKKKKKKKilling thread] '$tid' (queue-size:".($w-$r).")\n";
	    $thr->kill('KILL')->join;
	    $sem_threads->up();
	    print STDERR "[------DDDDDDDDDDDDDDead thread] '$tid' (queue-size:".($w-$r).")\n";
	}else{
	    print STDERR "[------RRRRRRRRRRRunning thread] '$tid' (queue-size:".($w-$r).")\n";
	}
	#my $thr = threads->object($tt->[0]);
	#if($thr->is_running() and $age<60){
	#    print STDERR "[++++++RRRRRRRRRRRRuning thread] '".($thr->tid())."'\n";
	    #push(@clean,$tt);
	#    next;
	#}

	#delete $thread_info->{$thr->tid()};
	#else{
	    #$thr->join;
	#}

    }
    #return @clean;
}

sub updateLinks{
    my ($urls,$links,$BASE_URL) = @_;
    my @cleaned_links = grep{/^$BASE_URL/}@$links;
    push(@$urls, @cleaned_links);
    #for(@cleaned_links){$seen->{$_}=1;}
}

sub getLinkedText{
    my ($url)= @_;

    print STDERR "Working with '$url'\n";
    my $mech = WWW::Mechanize->new(autocheck=>0,timeout=>15);
    my $res = $mech->get($url);
    return (undef,()) unless ($res->is_success() and $mech->is_html());

    print STDERR "Dump links of '$url'\n";
    my @all_links = $mech->find_all_links();
    my %h = map{$_=>1}
    grep{!/\.(pdf|css|bmp|(jpe?g)|png|tiff?|ico|gif|swf|wmv|aaf|flv|fla|swf|mp3|mp4|wav|aac|wma|(mpe?g)|js|exe)$/i}
    map{my $u=$_->url_abs(); $u=~s/#.*$//; $u}@all_links;

    print STDERR "Dump content of '$url'\n";
    my $text = html2plain($mech->content);
    $mech = undef;
    return ($text, keys(%h));
}

sub html2plain{
    my ($html) = @_;

    my $tree = HTML::TreeBuilder->new();
    $tree->parse( $html );
    $tree->eof();
    $tree->elementify(); # just for safety
    my $guard = HTML::AsText::Fix::object($tree,zwsp_char =>' ');
    my $c = $tree->as_text();
    $tree->delete;
    return $c;
}



sub file2hash{
    my ($file) = @_;
    open FILE, "<", $file or die join("\n","Cannot open file '$file'","$!")."\n";
    my %h = map{chomp; $_=>1}(<FILE>);
    return \%h;
}



sub readLine{
    my ($format,$i,$j,$lines) = @_;
    #print STDERR join(" ",$format, $$i, $$j, "'".join(" ",@$lines)."'")."\n";
    while(@$lines){
	my $l = shift @$lines;
	next if !defined($l) or $l=~/^\s*$/;
	return ($l,$lines);
    }

    while($$i<$$j){
	$$i=$$i+1;
	my $file = sprintf($format,int($$i/1000),$$i);
	my @ll = file2lines($file);
	#print STDERR "reading file '$file' ".join(" ",map{"'$_'"}(@ll))."\n";
	next unless @ll;
	my $l = shift @ll;
	next if (!(defined($l))) or $l=~/^\s*$/;

	#push(@$lines,file2lines("<".sprintf($format,$$i)));
	return ($l,\@ll);
    }
    return (undef,[]);
}
sub file2lines{
    my ($file) = @_;
    unless(-l $file){ return undef; }

    open FILE, "<", $file or die join("\n","$file","$!")."\n";
    my @lines = map{chomp;$_}(<FILE>);
    close(FILE);
    return @lines;
}

sub lines2file{
    my ($file, @lines) = @_;
    open FILE, ">", $file or die "$!";
    for(@lines){ print FILE "$_\n"; }
    close(FILE);
}

