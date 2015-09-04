#!/bin/bash

set -e
set -o xtrace

# Get data from the original directory

source config.ini

# Create data
mkdir -p $NNLM_DIR/data
for f in 0 1 2 3 4 5 6 7 8 9; do
    cat $data/run-0/fold-$f/train.sent | $LAMTRAM/script/unk-single.pl > $NNLM_DIR/data/train-$f.single
    cp $data/run-0/fold-$f/test.sent $NNLM_DIR/data/test-$f.sent
    for g in 0 1 2 3 4 5 6 7 8 9; do
        cat $data/run-0/fold-$f/tune/train-$g.sent | $LAMTRAM/script/unk-single.pl > $NNLM_DIR/data/train-$f-$g.single
        cp $data/run-0/fold-$f/tune/test-$g.sent $NNLM_DIR/data/test-$f-$g.sent
    done
done
