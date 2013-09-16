#!/bin/bash -f

set -e
set -u

FILE_DIR=$(dirname `readlink -f ${0}`)
BASE_DIR=$(dirname $FILE_DIR)
HOME_BIN_DIR=$BASE_DIR

git add $BASE_DIR

HOSTNAME=`hostname`
#if [ $HOSTNAME = "milan" ]; then
#    rsync ~/bin/xml_extract_values.pl $HOME_BIN_DIR/
#fi

if [ $# -ge 1 ]
then git commit -a -m "$1" 
else git commit -a
fi



