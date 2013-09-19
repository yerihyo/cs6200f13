#!/bin/bash -f

set -e
set -u

DATE=`date +"%Y%m%d_%H%M"`

FILE_DIR=$(dirname `readlink -f ${0}`)
BASE_DIR=$FILE_DIR
LOG_DIR=$FILE_DIR/log
LOG=$LOG_DIR/$DATE.log
CRAWLED_DIR=$FILE_DIR/crawled

rm -Rf $CRAWLED_DIR
mkdir -p $CRAWLED_DIR $LOG_DIR

cd $CRAWLED_DIR
agent_string='Mozilla/5.0 (X11; U; Linux i686; en-US; rv:1.8.1.6) Gecko/20070802 SeaMonkey/1.1.4'
wget -U "$agent_string" --recursive --accept=html,pdf --adjust-extension --wait=5 http://www.ccs.neu.edu >& $LOG
#wget -U "$agent_string" --recursive --accept=html,pdf --adjust-extension --wait=5 http://www.ccs.neu.edu 2>&1 > /dev/null | head -n10000 > $LOG

grep -A1 -P '(text/html)|(application/pdf)' $LOG | grep 'Saving to:' | awk '{print $3}' | sed 's/^`//' | sed "s/'$//" | head -n100 > $FILE_DIR/result.list
#grep -A1 -P '(text/html)|(application/pdf)' $LOG | grep 'Saving to:' | awk '{print $3}' | sed 's/^`www.ccs.neu.edu\///' | sed "s/'$//" | head -n100 > $FILE_DIR/result.list




#wget --no-parent --wait=10 --limit-rate=100K --recursive --accept=jpg,jpeg --no-directories http://somedomain/images/page1.html