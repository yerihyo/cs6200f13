#!/bin/bash

set -e 
set -u

#svn update
#if [[ $# != 0 ]]; then test_init=$1; else test_init=""; fi
test_init=1

#APP_LIST="destination attraction ticket trip"

FILE_DIR=$(dirname `readlink -f ${0}`)
SCRIPTS_DIR=$FILE_DIR
ROOT_DIR=$(dirname $FILE_DIR)

#svn update $TREVII_DIR
git pull origin master

chmod a+x $SCRIPTS_DIR/*
#chmod a+x $ROOT_DIR/bin/*


