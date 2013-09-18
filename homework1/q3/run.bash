#!/bin/bash -f

set -e
set -u

echo "You need to install scrapy in order to run this program"
sudo pip install scrapy
scrapy crawl ccs.neu.edu -o result/raw.csv -t csv

head -n101 result/raw.csv | tail -n100 > result/final.csv