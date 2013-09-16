#!/bin/bash 

set -e
set -u

FILE_DIR=$(dirname `readlink -f ${0}`)
SCRIPTS_DIR=$FILE_DIR
BASE_DIR=$(dirname $FILE_DIR)
DATA_DIR=$BASE_DIR/data
TMP_DIR=$BASE_DIR/tmp

MALLET=$BASE_DIR/opt/mallet/bin/mallet

MEMSIZE_KB=`grep MemTotal /proc/meminfo  | awk '{print $2}'`
MEMSIZE_MB=$(($MEMSIZE_KB/1024))

mkdir -p $TMP_DIR/examples/tmp $TMP_DIR/model

grep url data/examples.xml | sed -r 's/^\s*<url>//;s/\/?<\/url>$//' > $TMP_DIR/examples/urls

#rm -f $TMP_DIR/examples.all
i=1
cat $TMP_DIR/examples/urls | while read url; do
    echo ======== Working on URL "$url" ===========

    rm -Rf $TMP_DIR/examples/E$i/tmp
    mkdir -p $TMP_DIR/examples/E$i/tmp

    # Consider using lynx next time (lynx -force_html --dump --width=9999 [url])
    if [ ! -s $TMP_DIR/examples/E$i/content.txt.gz ]; then 
	$FILE_DIR/extract_linked_text.pl -U $url -l en  -O $TMP_DIR/examples/E$i/tmp -m $MEMSIZE_MB #> $TMP_DIR/content.tmp #-O $TMP_DIR/examples/E$i/tmp

	if find $TMP_DIR/examples/E$i/tmp/ -maxdepth 0 -empty | read; then echo "empty"
	else cat $TMP_DIR/examples/E$i/tmp/* > $TMP_DIR/examples/E$i/content.txt.gz; fi
	#gzip -f $TMP_DIR/content.tmp
	#mv $TMP_DIR/content.tmp.gz $TMP_DIR/examples/E$i/content.txt.gz
	#wget $url -O $TMP_DIR/examples/E$i/index.html
    fi
    i=$(($i + 1))
    #break
done
#exit

n=`wc -l $TMP_DIR/examples/urls | awk '{print $1}'`
if [ ! -s $TMP_DIR/examples/model/all.txt ]; then 
    perl -e 'for $i(1..'$n'){ open FILE, "zcat '$TMP_DIR'/examples/E$i/content.txt.gz |"; print "$i "; for(<FILE>){chomp;print $_;print " ";} print "\n"; close FILE;}' > $TMP_DIR/examples/model/all.txt
fi

#if [ ! -s $TMP_DIR/examples/model/all.bag_of_words ]; then 
    $MALLET import-file --keep-sequence --line-regex "^(\S*)[\s]*(.*)$" --label 0 --name 1 --data 2 --input $TMP_DIR/examples/model/all.txt --output $TMP_DIR/examples/model/all.bag_of_words --remove-stopwords --print-output
#fi

#if [ ! -s $TMP_DIR/examples/model/all.bag_of_words.pruned ]; then 
    $MALLET prune --input $TMP_DIR/examples/model/all.bag_of_words --prune-count 10 --output $TMP_DIR/examples/model/all.bag_of_words.pruned
#fi

$MALLET train-topics --input $TMP_DIR/examples/model/all.bag_of_words.pruned \
    --output-model $TMP_DIR/examples/model/all.model \
    --num-topics 10 \
    --num-threads 4 \
    --num-iterations 1000 \
    --output-doc-topics $TMP_DIR/examples/model/all.doc.topics \
    --output-topic-keys $TMP_DIR/examples/model/all.topic.keys \

    #--output-state $TMP_DIR/examples/model/all.state \
    #--topic-word-weights-file $TMP_DIR/examples/model/all.topic.word.weights \
    #--word-topic-counts-file $TMP_DIR/examples/model/all.topic.counts \
    #--xml-topic-report $TMP_DIR/examples/model/all.topic.report \
    #--xml-topic-phrase-report $TMP_DIR/examples/model/all.topic.phrase.report \



#POST https://www.readability.com/api/rest/v1/bookmarks
#Content-Type: application/x-www-form-urlencoded

#url=http://blog.arc90.com/2010/11/30/silence-is-golden/&favorite=1