#!/bin/bash

set -e 
set -o xtrace

# Calculate Boostrap Resampling

if [[ -e other/bootstrap.result ]]; then
    rm other/bootstrap.result
fi

for x in fold-normal fold-empty fold-notc; do
    echo "==== $x ====" >> other/bootstrap.result
    for y in baseline geo news question; do
        echo "++ $y ++" >> other/bootstrap.result
        script/test/bootstrap-resampling.py --baseline freeze/$x/shuffled/direct/run-0/fold-*/test/nbest.stats.res --gs data/full-question/run-0/fold-*/test.ref --input freeze/$x/shuffled/$y/run-0/fold-*/test/nbest.stats.res >> other/bootstrap.result
        echo "-- NNLM --" >> other/bootstrap.result
        script/test/bootstrap-resampling.py --baseline freeze/$x/shuffled/direct/run-0/fold-*/test/nbest.stats.res --gs data/full-question/run-0/fold-*/test.ref --input freeze/$x/shuffled/$y/run-0/fold-*/test-nnlm/nbest.stats.res >> other/bootstrap.result
    done
    echo "" >> other/bootstrap.result
done
