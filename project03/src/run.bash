#!/bin/bash

set -e
set -u

FILE_DIR=$(dirname `readlink -f ${0}`)
# FILE_DIR=`pwd`/src
SRC_DIR=$FILE_DIR
BASE_DIR=$(dirname $SRC_DIR)
DATA_DIR=$BASE_DIR/data
OUT_DIR=$BASE_DIR/out
TMP_DIR=$BASE_DIR/tmp

mkdir -p $OUT_DIR/wc $TMP_DIR

# term frequency for each document
if [ '' ]; then
    rm -f $TMP_DIR/command.list
    find $DATA_DIR/CACM/ -name '*.html' | while read f; do
        b=`basename $f`
        echo "$FILE_DIR/file2wc.bash $f > $OUT_DIR/wc/$b.wc" >> $TMP_DIR/command.list
    done
    cat $TMP_DIR/command.list | parallel
fi

find $OUT_DIR/wc/ -name "*.wc" \
    | $FILE_DIR/tf_files2inverted_index.py