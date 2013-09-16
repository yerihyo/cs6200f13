#!/bin/bash

set -e
set -u

FILE_DIR=$(dirname `readlink -f ${0}`)
SCRIPTS_DIR=$FILE_DIR
BASE_DIR=$(dirname $FILE_DIR)

MALLET_DIR=$BASE_DIR/opt/mallet
MALLET=$MALLET_DIR/bin/mallet


