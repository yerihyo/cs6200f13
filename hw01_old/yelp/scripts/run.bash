#!/bin/bash

set -e
set -u

FILE_DIR=$(dirname `readlink -f ${0}`)
SCRIPTS_DIR=$FILE_DIR
YELP_DIR=$(dirname $SCRIPTS_DIR)
TMP_DIR=$YELP_DIR/tmp
DATA_DIR=$YELP_DIR/data

#query="term=food&limit=20&location=San+Francisco,CA"
#query="term=food&location=San+Francisco,CA"

#encoded_query=`echo $query | perl -MURI::Escape -lne 'print uri_escape($_);'`
#url_header="http://api.yelp.com/v2/search?$encoded_query"

#OAUTH_NONCE=`perl -e '@a = ('A'..'Z', 'a'..'z', 0..9); print join("",map{ $a[rand(scalar(@a))] }(0..31))."\n";'`
OAUTH_CONSUMER_KEY="RRMrJoxjdVxsCQ2UCOUKeA"
OAUTH_CONSUMER_SECRET_KEY="uyDSORQe4u5jjudPin9pd_9CLaQ"
OAUTH_TOKEN="j4G8m9zh0ssyz6BfCMadbcNx56g2-1oS"
OAUTH_TOKEN_SECRET="gUleQ1GzonHZ_TcwrlFvrvIHQXE"

mkdir -p $DATA_DIR/search $TMP_DIR

#cat $DATA_DIR/neighborhood.html | $FILE_DIR/yelp_html2list.pl > $DATA_DIR/neighborhood.list
#cat $DATA_DIR/category.html | $FILE_DIR/yelp_html2list.pl | awk -F, '{print $(NF-1)}' | awk -F\( '{print $NF}' | sed 's/)//g' | sort -u > $DATA_DIR/category.list
#exit

cat $DATA_DIR/neighborhood.list | while read l; do
    loc=`echo $l | perl -MURI::Escape -lne 'print "location=".uri_escape($_)'`
    PATH_LOC=`echo $l | perl -F, -lane 'print join("/", reverse @F)'`
    OUT_LOC_DIR="$DATA_DIR/search/$PATH_LOC"
    #OUT_LOC_DONE_DIR="$OUT_LOC_DIR/done"
    #mkdir -p $OUT_LOC_DONE_DIR

    if [ -e $OUT_LOC_DIR/done ]; then continue; fi

    #cat $DATA_DIR/category.list | while read c; do
    #if [ -e $OUT_LOC_DONE_DIR/$c.done ]; then continue; fi

    #query="$loc&category_filter=$c&sort=2"
    query="$loc&sort=2"
    n=0; total=0; page=1
    while [ $total -eq 0 -o $n -lt $total ]; do 
	url=`$FILE_DIR/yelp_query2url.pl -c $OAUTH_CONSUMER_KEY -C $OAUTH_CONSUMER_SECRET_KEY -t $OAUTH_TOKEN -T $OAUTH_TOKEN_SECRET -p "search" -q "$query&offset=$n" `

	OUT_PAGE_DIR="$OUT_LOC_DIR/$page"
	if [ 1 ]; then wget $url -O $TMP_DIR/search.json.tmp; fi

	cat $TMP_DIR/search.json.tmp | python -m json.tool > $TMP_DIR/search.json
	cat $TMP_DIR/search.json | $FILE_DIR/json2list.pl -O "$OUT_PAGE_DIR" > $TMP_DIR/search.stat

	count=`head -n1 $TMP_DIR/search.stat`
	tmp_total=`tail -n1 $TMP_DIR/search.stat`
	if [ $tmp_total -eq 0 ]; then break
	elif [ $total -eq 0 ]; then total=$tmp_total
	elif [ $count -ge "1000" ]; then echo "TOO MANY PLACES in '$loc' '$c'!!"; break
	elif [ $total -ne $tmp_total ]; then echo "TOTAL CHANGED?!"; exit 1; fi
	
	n=$(($n + $count))
	page=$(($page + 1))
	echo Downloaded $n businesses out of $total
    done

    #echo "done" > $OUT_LOC_DONE_DIR/$c.done
    #done
    echo "done" > $OUT_LOC_DIR/done
    #exit
done