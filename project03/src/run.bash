#!/bin/bash

set -e
set -u


FILE_DIR=$(dirname `readlink -f ${0}`)
# FILE_DIR=`pwd`/src
SRC_DIR=$FILE_DIR
BASE_DIR=$(dirname $SRC_DIR)
DATA_DIR=$BASE_DIR/data

#find $DATA_DIR/ -name '*.html' 
tail -n +3 $DATA_DIR/CACM-0870.html \
    | head -n -3 \
    | perl -MScalar::Util=looks_like_number -lane 'next if $#F==2 && scalar(grep{(looks_like_number $_)}@F)==$#F+1; print $_;' 
    