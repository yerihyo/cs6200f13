#!/bin/bash

set -e
set -u

FILE_DIR=$(dirname `readlink -f ${0}`)
BASE_DIR=$(dirname $FILE_DIR)
# BASE_DIR=`pwd`
DATA_DIR=$BASE_DIR/data
SRC_DIR=$BASE_DIR/src
BIN_DIR=$BASE_DIR/bin
OUT_DIR=$BASE_DIR/out
BASE_URL="http://fiji4.ccs.neu.edu/~zerg/lemurcgi/lemur.cgi"
#QUERIES=$DATA_DIR/desc.51-100.short

mkdir -p $OUT_DIR

if [ ! -s $OUT_DIR/dump.result ]; then
    wget "$BASE_URL?d=1&g=p&v=the&v=of&v=and&v=to&v=in&v=is&v=a&v=no&v=it&v=on&v=test&v=0&v=1&v=n&v=m&v=est&v=ny&v=edt&v=g&v=am&v=pm" -O $OUT_DIR/dump.result
    tail -n +9 $OUT_DIR/dump.result | head -n -8 | $FILE_DIR/get_doc_len.py
fi

type=pm
cat $DATA_DIR/desc.51-100.short \
    | $FILE_DIR/query2url.py "$BASE_URL" \
    | while read q_no url; do

    q_id="q$q_no"
    OUT_Q_DIR=$OUT_DIR/query/$q_id
    mkdir -p $OUT_Q_DIR

    echo === wget "'$url'" ===
    wget $url -O $OUT_Q_DIR/$type.result

    tail -n +9 $OUT_Q_DIR/$type.result | head -n -8 > $OUT_DIR/$q_id/$type.result.cln

    cat $OUT_DIR/$q_id/$type.result.cln | $FILE_DIR/parse_result.py
done