#!/bin/bash 
# Script to generate the splited data required for generating the experiment
# Philip Arthur (philip.arthur30@gmail.com)

set -e 
 
source config.ini

input=metadata/geoquery/split-880
dataid=id/wong-split

if [[ ! -d $dataid ]]; then 
mkdir $dataid

# FOR EACH RUN
for i in {0..9}; do
# FOR EACH FOLD
for j in {0..9}; do
    mkdir -p $dataid/run-$i/fold-$j/tune
    cp $input/run-$i/fold-$j/train-N792 $dataid/run-$i/fold-$j/train
    cp $input/run-$i/fold-$j/test $dataid/run-$i/fold-$j/test
    script/data/split-tune.py $dataid/run-$i/fold-$j/train $dataid/run-$i/fold-$j/tune
done # fold
done # run

else
    echo "Directory $dataid is exist"
fi
