#!/bin/bash -f

set -e
set -u

FILE_DIR=$(dirname `readlink -f ${0}`)
BASE_DIR=$(dirname $FILE_DIR)
Q3_DIR=$BASE_DIR/q3
SCRIPTS_DIR=$FILE_DIR
DATA_DIR=$BASE_DIR/data
OUT_DIR=$Q3_DIR/out

cat $DATA_DIR/pg11.nopunc.txt | $SCRIPTS_DIR/wc.pl > $OUT_DIR/log.points

echo 'd=read.table("out/log.points"); lm(d[,2]~d[,1])' | R --no-save > $OUT_DIR/r.log