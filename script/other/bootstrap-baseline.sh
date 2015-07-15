#!/bin/bash

set -e 
set -o xtrace

# Calculate Boostrap Resampling

if [[ -e other/bootstrap-baseline.result ]]; then
    rm other/bootstrap-baseline.result
fi

for x in fold-normal fold-empty fold-notc; do
    echo "==== $x ====" >> other/bootstrap-baseline.result
    for y in geo news question; do
        echo "++ $y ++" >> other/bootstrap-baseline.result
        script/test/bootstrap-resampling.py --baseline freeze/$x/shuffled/baseline/run-0/fold-*/test/nbest.stats.res --gs data/full-question/run-0/fold-*/test.ref --input freeze/$x/shuffled/$y/run-0/fold-*/test/nbest.stats.res >> other/bootstrap-baseline.result
        echo "-- NNLM --" >> other/bootstrap-baseline.result
        script/test/bootstrap-resampling.py --baseline freeze/$x/shuffled/baseline/run-0/fold-*/test/nbest.stats.res --gs data/full-question/run-0/fold-*/test.ref --input freeze/$x/shuffled/$y/run-0/fold-*/test-nnlm/nbest.stats.res >> other/bootstrap-baseline.result
    done
    echo "" >> other/bootstrap-baseline.result
done
