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

mkdir -p $TMP_DIR/trevii
echo "select id,homepageURL from attraction_attraction where homepageURL <> '';" \
    | mysql --skip-column-names -u root --password=tretrevii trevii \
    | perl -lane 'print join("\t","A".$F[0],$F[1],$F[1])' > $TMP_DIR/trevii/urls

#if [ -d $TMP_DIR/trevii/crawl ]; then
#    mv $TMP_DIR/trevii/crawl $TMP_DIR/trevii/crawl_old
#    rm -Rf $TMP_DIR/trevii/crawl_old &
#fi

if [ ! -s $TMP_DIR/trevii/crawl/ckpts ]; then
    cat $TMP_DIR/trevii/urls | while read name url BASE_URL; do
	if [ -s $TMP_DIR/trevii/crawl/$name/ckpts ]; then continue; fi

	if [ -d $TMP_DIR/trevii/crawl/$name/W ]; then
	    mv $TMP_DIR/trevii/crawl/$name/W $TMP_DIR/trevii/crawl/$name/W_old
	    rm -Rf $TMP_DIR/trevii/crawl/$name/W_old &
	fi
	mkdir -p $TMP_DIR/trevii/crawl/$name

	$FILE_DIR/extract_linked_text.pl -i "$name $url $BASE_URL" -l en -O $TMP_DIR/trevii/crawl/$name -m $MEMSIZE_MB -t run01 -n 1000 #>& $TMP_DIR/trevii/crawl/$name/log
	echo "done" > $TMP_DIR/trevii/crawl/$name/ckpts
    done
    echo "done" > $TMP_DIR/trevii/crawl/ckpts
fi


#$FILE_DIR/extract_linked_text.pl -i /tmp/urls -l en -O $TMP_DIR/trevii/crawl -m $MEMSIZE_MB

#tail -f log

if [ ! -s $TMP_DIR/trevii/crawl/all.txt ]; then
    cat $TMP_DIR/trevii/urls | while read name url BASE_URL; do
	if [ ! -s $TMP_DIR/trevii/crawl/$name/all.txt ]; then
	    find $TMP_DIR/trevii/crawl/$name/raw/ -name "contents.txt" \
		| perl -ne 'BEGIN{print "'$name' ";} chomp; open FILE, "<", $_ or die "$!"; while(<FILE>){chomp;print "$_ ";} close(FILE); END{print "\n";}' \
		> $TMP_DIR/trevii/crawl/$name/all.txt
        fi
    done
    cat $TMP_DIR/trevii/crawl/*/all.txt > $TMP_DIR/trevii/crawl/all.txt
fi

#exit

MODEL_DIR=$TMP_DIR/trevii/model
mkdir -p $MODEL_DIR

$MALLET import-file --keep-sequence --line-regex "^(\S*)[\s]*(.*)$" --label 0 --name 1 --data 2 --input $TMP_DIR/trevii/crawl/all.txt --output $MODEL_DIR/all.bag_of_words --remove-stopwords --print-output

$MALLET prune --input $MODEL_DIR/all.bag_of_words --prune-count 10 --output $MODEL_DIR/all.bag_of_words.pruned

$MALLET train-topics --input $MODEL_DIR/all.bag_of_words.pruned \
    --output-model $MODEL_DIR/all.model \
    --num-topics 10 \
    --num-threads 4 \
    --num-iterations 1000 \
    --output-doc-topics $MODEL_DIR/all.doc.topics \
    --output-topic-keys $MODEL_DIR/all.topic.keys

exit

cat $TMP_DIR/trevii/urls | while read name url BASE_URL; do
    echo ======== Working on URL "$url" ===========
    
    rm -Rf $TMP_DIR/trevii/$name/tmp
    mkdir -p $TMP_DIR/trevii/$name/tmp
    
    # Consider using lynx next time (lynx -force_html --dump --width=9999 [url])
    if [ ! -s $TMP_DIR/trevii/$name/content.txt.gz ]; then 
	$FILE_DIR/extract_linked_text.pl -U $url -l en  -O $TMP_DIR/trevii/$name/tmp -m $MEMSIZE_MB #> $TMP_DIR/content.tmp #-O $TMP_DIR/examples/$name/tmp
	
	if find $TMP_DIR/trevii/$name/tmp/ -maxdepth 0 -empty | read; then echo "empty"
	else find $TMP_DIR/trevii/$name/tmp/ -name "*.gz" | xargs cat > $TMP_DIR/trevii/$name/content.txt.gz; fi
    fi
    #break
done