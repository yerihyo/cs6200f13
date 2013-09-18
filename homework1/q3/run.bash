#!/bin/bash -f

set -e
set -u

echo "You need to install scrapy in order to run this program"
sudo pip install scrapy
scrapy crawl ccs.neu.edu -o result/raw.csv -t csv

tail -n +2 result/raw.csv | head -n100  > result/final.csv