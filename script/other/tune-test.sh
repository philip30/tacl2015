#!/bin/bash

set -e
set -o xtrace

target_dir=fold-n/shuffled/question
working_dir=temp/$target_dir
data=data/keyword-shuffle/run-0/fold-0/tune
letrac=~/dev/letrac
db_config=config/mysql.config
n_best=300
threads=24
trg_factors=2
travatar=~/dev/travatar
geoquery="metadata/geoquery/eval.pl"

for x in 0 1 2 3 4 5 6 7 8 9; do
    mkdir -p $working_dir/fold-0-$x
    script/tune/replace-tm.py -tm $target_dir/run-0/fold-0/tune/train-$x/model/rule-table.gz -i $target_dir/run-0/fold-0/tune/travatar.ini > $working_dir/travatar-$x.ini 
        
    script/run-test.pl -working-dir $working_dir/fold-0-$x -geoquery $geoquery -travatar $travatar -travatar-config $working_dir/travatar-$x.ini -src $data/test-$x.sent -ref $data/test-$x.mrl.time.ref -letrac $letrac -database-config $db_config -driver-function execute_query -n-best $n_best -force -threads $threads -trg-factors $trg_factors
done

script/test/calculate-score.py -i $working_dir/fold-0-*/nbest.stats.res -gs $data/test-*.mrl.time.ref > $working_dir/result.txt
