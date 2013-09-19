#!/bin/bash -f

set -e
set -u

FILE_DIR=$(dirname `readlink -f ${0}`)
BASE_DIR=$(dirname $FILE_DIR)
SCRIPTS_DIR=$FILE_DIR
DATA_DIR=$BASE_DIR/data

$SCRIPTS_DIR/parse.pl $DATA_DIR/pg11.clean.txt > $DATA_DIR/pg11.nopunc.txt 

cat $DATA_DIR/pg11.nopunc.txt | $SCRIPTS_DIR/wc.pl
