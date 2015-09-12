#!/bin/bash

set -e 
set -o xtrace

# Calculate Boostrap Resampling

output=bootstrap-result
mkdir -p output

#### Bootstrap resampling of 3-LM systems against the direct KW-MR system
if [[ -e $output/bootstrap.result ]]; then
    rm $output/bootstrap.result
fi

for x in fold-normal fold-empty fold-notc; do
    echo "==== $x ====" >> $output/bootstrap.result
    for y in baseline geo news question; do
        echo "++ $y ++" >> $output/bootstrap.result
        script/test/bootstrap-resampling.py --baseline $x/shuffled/direct/run-0/fold-*/test/nbest.stats.res --gs data/full-question/run-0/fold-*/test.ref --input $x/shuffled/$y/run-0/fold-*/test/nbest.stats.res >> $output/bootstrap.result
        echo "-- NNLM --" >> $output/bootstrap.result
        script/test/bootstrap-resampling.py --baseline $x/shuffled/direct/run-0/fold-*/test/nbest.stats.res --gs data/full-question/run-0/fold-*/test.ref --input $x/shuffled/$y/run-0/fold-*/test-nnlm/nbest.stats.res >> $output/bootstrap.result
    done
    echo "" >> $output/bootstrap.result
done

#### Bootstrap resampling of systems with Language model against the system without language model
if [[ -e $output/bootstrap-baseline.result ]]; then
    rm $output/bootstrap-baseline.result
fi

mkdir -p $output

for x in fold-normal fold-empty fold-notc; do
    echo "==== $x ====" >> $output/bootstrap-baseline.result
    for y in geo news question; do
        echo "++ $y ++" >> $output/bootstrap-baseline.result
        script/test/bootstrap-resampling.py --baseline $x/shuffled/baseline/run-0/fold-*/test/nbest.stats.res --gs data/full-question/run-0/fold-*/test.ref --input $x/shuffled/$y/run-0/fold-*/test/nbest.stats.res >> $output/bootstrap-baseline.result
        echo "-- NNLM --" >> $output/bootstrap-baseline.result
        script/test/bootstrap-resampling.py --baseline $x/shuffled/baseline/run-0/fold-*/test/nbest.stats.res --gs data/full-question/run-0/fold-*/test.ref --input $x/shuffled/$y/run-0/fold-*/test-nnlm/nbest.stats.res >> $output/bootstrap-baseline.result
    done
    echo "" >> $output/bootstrap-baseline.result
done

echo "Result can be seen in other/bootstra-baseline.result"
