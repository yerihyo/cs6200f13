#!/bin/bash -f

set -e
set -u

FILE_DIR=$(dirname `readlink -f ${0}`)
BASE_DIR=$(dirname $FILE_DIR)
SCRIPTS_DIR=$FILE_DIR
DATA_DIR=$BASE_DIR/data

cat $DATA_DIR/pg11.nopunc.txt | $SCRIPTS_DIR/wc.pl
