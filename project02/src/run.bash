#!/bin/bash

set -e
set -u

FILE_DIR=$(dirname `readlink -f ${0}`)
BASE_DIR=$(dirname $FILE_DIR)
# BASE_DIR=`pwd`
DATA_DIR=$BASE_DIR/data
TMP_DIR=$BASE_DIR/tmp
SRC_DIR=$BASE_DIR/src
BIN_DIR=$BASE_DIR/bin
OUT_DIR=$BASE_DIR/out
BASE_URL="http://fiji4.ccs.neu.edu/~zerg/lemurcgi/lemur.cgi"
#QUERIES=$DATA_DIR/desc.51-100.short
echoerr() { echo "$@" 1>&2; }

mkdir -p $OUT_DIR $TMP_DIR

#if [ ! -s $OUT_DIR/dump.result ]; then
#    wget "$BASE_URL?d=1&g=p&v=the&v=of&v=and&v=to&v=in&v=is&v=a&v=no&v=it&v=on&v=test&v=0&v=1&v=n&v=m&v=est&v=ny&v=edt&v=g&v=am&v=pm" -O $OUT_DIR/dump.result
#    tail -n +9 $OUT_DIR/dump.result | head -n -8 | $FILE_DIR/get_doc_len.py
#fi

for pm in pm; do # stop & stem
    echoerr "=== Option '$pm' ===="
    options=`echo $pm | sed 's/^none//' | sed -e "s/\(.\)/ -\1/g"`
    OUT_PM_DIR=$OUT_DIR/$pm
    mkdir -p $OUT_PM_DIR/wget

    # Query lemur
    cat $DATA_DIR/desc.51-100.short | grep -v '^$' | while read q_no_raw q_str; do
        q_no=`echo $q_no_raw | sed 's/\.$//'`
        if [ -s $OUT_PM_DIR/wget/Q$q_no.cln ]; then continue; fi

        url=`echo "$q_str" | $FILE_DIR/query2url.py $options "$BASE_URL"`

        echoerr "=== Processing 'Q$q_no' : '$url' ===="

	    echoerr === wget "'$url'" ===
	    wget $url -O $OUT_PM_DIR/wget/Q$q_no
        tail -n +9 $OUT_PM_DIR/wget/Q$q_no | head -n -8 > $OUT_PM_DIR/wget/Q$q_no.cln
    done


    # real retrieval
    for fe in BM25_log; do #LM_JM; do #BM25_log; do #LM_JM; do # OKTF_IDF; do
        echoerr "=== Using '$fe' ===="
        mkdir -p $OUT_PM_DIR/result/$fe

        cat $DATA_DIR/desc.51-100.short | grep -v '^$' | while read q_no_raw q_str; do
            q_no=`echo $q_no_raw | sed 's/\.$//'`
            if [ -s $OUT_PM_DIR/result/$fe/Q$q_no ]; then continue; fi

            echoerr "=== Working on 'Q$q_no' ===="
            cat $OUT_PM_DIR/wget/Q$q_no.cln \
                | $FILE_DIR/parse_wget.py $DATA_DIR/doclist.txt $fe $q_no $options "$q_str" \
                > $OUT_PM_DIR/result/$fe/Q$q_no

            continue

            # Local evaluation setup for debugging
            cat $DATA_DIR/qrel.irclass10X1 | perl -lane 'print join(" ",@F) if $F[0]=='$q_no';' \
                > $TMP_DIR/Q$q_no.qrel.irclass10X1
            $BIN_DIR/trec_eval -q $TMP_DIR/Q$q_no.qrel $OUT_PM_DIR/result/$fe/Q$q_no
        done
        cat $OUT_PM_DIR/result/$fe/Q* > $OUT_PM_DIR/result/$fe.all

        $BIN_DIR/trec_eval -q $DATA_DIR/qrels.adhoc.51-100.AP89 $OUT_PM_DIR/result/$fe.all > $OUT_PM_DIR/result/$fe.eval
        cat $OUT_PM_DIR/result/$fe.eval
    done
done