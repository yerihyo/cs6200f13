#!/bin/bash -f

set -e
set -u

FILE_DIR=$(dirname `readlink -f ${0}`)
BASE_DIR=$FILE_DIR

cd $BASE_DIR
rm -f $BASE_DIR/result/raw.csv $BASE_DIR/result/final.csv
scrapy crawl ccs.neu.edu -o $BASE_DIR/result/raw.csv -t csv

tail -n +2 $BASE_DIR/result/raw.csv | head -n100  > $BASE_DIR/result/final.csv