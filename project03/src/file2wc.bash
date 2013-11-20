#!/bin/bash

set -e
set -u

file=$1

FILE_DIR=$(dirname `readlink -f ${0}`)
# FILE_DIR=`pwd`/src
SRC_DIR=$FILE_DIR
BASE_DIR=$(dirname $SRC_DIR)
DATA_DIR=$BASE_DIR/data

tail -n +3 $file \
    | head -n -3 \
    | perl -MScalar::Util=looks_like_number -lane 'next if $#F==2 && scalar(grep{(looks_like_number $_)}@F)==$#F+1; print $_;' \
    | head -n -2 \
    | sed 's/\.//g' \
    | sed 's/[^[:alnum:]][^[:alnum:]]*/ /g' \
    | tr '[:upper:]' '[:lower:]' \
    | sed 's/ /\n/g' \
    | sed '/^\s*$/d' \
    | $FILE_DIR/grep_dict_by_dictword.pl -v -h $DATA_DIR/stoplist.txt \
    | sort \
    | uniq -c

