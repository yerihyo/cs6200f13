#!/bin/bash -f

set -e
set -u

#FOLDER=data/crawled
FOLDER=crawled
rm -Rf $FOLDER
mkdir -p $FOLDER

cd $FOLDER
agent_string='Mozilla/5.0 (X11; U; Linux i686; en-US; rv:1.8.1.6) Gecko/20070802 SeaMonkey/1.1.4'
wget -U "$agent_string" --recursive --accept=html,pdf --adjust-extension --wait=5 http://www.ccs.neu.edu

#wget --no-parent --wait=10 --limit-rate=100K --recursive --accept=jpg,jpeg --no-directories http://somedomain/images/page1.html