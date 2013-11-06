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

mkdir -p $OUT_DIR $TMP_DIR

#if [ ! -s $OUT_DIR/dump.result ]; then
#    wget "$BASE_URL?d=1&g=p&v=the&v=of&v=and&v=to&v=in&v=is&v=a&v=no&v=it&v=on&v=test&v=0&v=1&v=n&v=m&v=est&v=ny&v=edt&v=g&v=am&v=pm" -O $OUT_DIR/dump.result
#    tail -n +9 $OUT_DIR/dump.result | head -n -8 | $FILE_DIR/get_doc_len.py
#fi

for pm in none; do # stop & stem
    echo "=== Option '$pm' ===="
    options=`echo $pm | sed 's/^none//' | sed -e "s/\(.\)/ -\1/g"`
    OUT_PM_DIR=$OUT_DIR/$pm
    mkdir -p $OUT_PM_DIR/wget

    cat $DATA_DIR/desc.51-100.short | grep -v '^$' | while read q_no_raw q_str; do
        q_no=`echo $q_no_raw | sed 's/\.$//'`
        url=`echo "$q_str" | $FILE_DIR/query2url.py $options "$BASE_URL"`

        echo "=== Processing 'Q$q_no' : '$url' ===="

        if [ ! -s $OUT_PM_DIR/wget/Q$q_no.cln ]; then
	        echo === wget "'$url'" ===
	        wget $url -O $OUT_PM_DIR/wget/Q$q_no
            tail -n +9 $OUT_PM_DIR/wget/Q$q_no | head -n -8 > $OUT_PM_DIR/wget/Q$q_no.cln
        fi

        # cat $OUT_PM_DIR/wget/Q$q_no.cln | perl -lane 'print join("\t",@F) if $#F==1 or $F[0]==60222'
        break # DEBUG
    done
    #break

    for fe in OKTF; do
        echo "=== Using '$fe' ===="
        mkdir -p $OUT_PM_DIR/result/$fe

        cat $DATA_DIR/desc.51-100.short | grep -v '^$' | while read q_no_raw q_str; do
            q_no=`echo $q_no_raw | sed 's/\.$//'`
            echo "=== Working on 'Q$q_no' ===="

            cat $OUT_PM_DIR/wget/Q$q_no.cln \
                | $FILE_DIR/parse_wget.py $DATA_DIR/doclist.txt $fe $q_no $options "$q_str" \
                > $OUT_PM_DIR/result/$fe/Q$q_no

            #continue
            #break # DEBUG
            cat $DATA_DIR/qrels.adhoc.51-100.AP89 | perl -lane 'print join(" ",@F) if $F[0]=='$q_no';' \
                > $TMP_DIR/Q$q_no.qrel.adhoc
            cat $DATA_DIR/qrel.irclass10X1 | perl -lane 'print join(" ",@F) if $F[0]=='$q_no';' \
                > $TMP_DIR/Q$q_no.qrel.irclass10X1
            $BIN_DIR/trec_eval -q $TMP_DIR/Q$q_no.qrel.adhoc $OUT_PM_DIR/result/$fe/Q$q_no
            #$BIN_DIR/trec_eval -q $TMP_DIR/Q$q_no.qrel.irclass10X1 $OUT_PM_DIR/result/$fe/Q$q_no
            break
        done
        cat $OUT_PM_DIR/result/$fe/Q* > $OUT_PM_DIR/result/$fe.all

        #$BIN_DIR/trec_eval -q $DATA_DIR/qrels.adhoc.51-100.AP89 $OUT_PM_DIR/result/$fe.all
        #break # DEBUG
    done
done