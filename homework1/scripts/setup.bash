#!/bin/bash -f


set -e
set -u

FILE_DIR=$(dirname `readlink -f ${0}`)
SCRIPTS_DIR=$FILE_DIR
BASE_DIR=$(dirname $FILE_DIR)
OPT_DIR=$BASE_DIR/opt

source $BASE_DIR/config

echo "Install cs5200f13"
sudo apt-get -y install libxml-dom-perl libwww-mechanize-perl liblingua-identify-perl liblist-moreutils-perl libipc-system-simple-perl
sudo apt-get -y install lynx-cur

sudo perl -MCPAN -e "install HTML::AsText::Fix"


### 3rd-party opt
mkdir -p $OPT_DIR
cd $OPT_DIR

## mallet
if [ ! -d $MALLET_VERSION ]; then
    wget http://mallet.cs.umass.edu/dist/$MALLET_VERSION.tar.gz
    tar -zxvf $MALLET_VERSION.tar.gz
fi
if [ ! -L mallet ]; then ln -s $MALLET_VERSION mallet; fi


## END OF 3rd-part opt

