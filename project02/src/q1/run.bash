#!/bin/bash

set -e
set -u

FILE_DIR=$(dirname `readlink -f ${0}`)
Q_DIR=$FILE_DIR
Q=$(basename $Q_DIR)
SRC_DIR=$(dirname $Q_DIR)
BASE_DIR=$(dirname $SRC_DIR)

DATA_DIR=$BASE_DIR/data
BIN_DIR=$BASE_DIR/bin
LIB_DIR=$BASE_DIR/lib
OUT_DIR=$BASE_DIR/out/$Q

mkdir -p $OUT_DIR

type=pm
$LIB_DIR/terms2url.py "http://fiji4.ccs.neu.edu/~zerg/lemurcgi/lemur.cgi" | xargs -i wget "{}" -O $OUT_DIR/$type