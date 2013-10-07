#!/bin/bash

set -e
set -u

FILE_DIR=$(dirname `readlink -f ${0}`)
BASE_DIR=$(dirname $FILE_DIR)
# BASE_DIR=`pwd`
SRC_DIR=$BASE_DIR/src
OUT_DIR=$BASE_DIR/out
DATA_DIR=$BASE_DIR/data

# Calculate PageRank of sample graph
$SRC_DIR/pagerank.py $DATA_DIR/sample_inlinks --halt_iteration 100 --print_probs $OUT_DIR/sample.probs

# Calculate PageRank of wt2g_inlinks graph
$SRC_DIR/pagerank.py $DATA_DIR/wt2g_inlinks --halt_perplexity 1.0 --print_perp $OUT_DIR/wt2g.perp --print_result $OUT_DIR/wt2g.result --print_urls $OUT_DIR/wt2g.html

# Rank nodes by inlink
cat $DATA_DIR/wt2g_inlinks | perl -lane '$h{$F[0]}=$#F;END{@k=sort{$h{$b}<=>$h{$a}}keys(%h); for(@k[0..49]){print join(" ",$_,$h{$_});}}'  > $OUT_DIR/wt2g.inlinks

