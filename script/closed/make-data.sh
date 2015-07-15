#!/bin/bash

set -e
set -o xtrace

#### Prepare ID
id=id/closed
wongid=id/wong-split
test_inp=metadata/geoquery/geokey.sent

if [[ -d $id ]]; then
    rm -r $id
fi

mkdir -p $id/tune
script/closed/make-id.py > $id/train

for i in 0 1 2 3 4 5 6 7 8 9; do
    cp $wongid/run-0/fold-$i/train $id/tune/train-$i
    cp $wongid/run-0/fold-$i/test $id/tune/test-$i
done

#### Prepare data
input=metadata/geoquery/geoqueries880
data=data/closed
mkdir -p $data

script/data/extract-logic.py < $input > $data/mrl 2> $data/sent 
script/data/query.py "execute_query" < $data/mrl > $data/query

sed -i 's/which/what/g' $data/sent

cp $test_inp $data/keyword-query.sent

script/data/merge-logic.py $data/sent $data/mrl > $data/pairs

cp metadata/geoquery/gold-standard $data
cp metadata/geoquery/time $data

mkdir -p $data/tune
script/data/retrieve-lines.py $data/pairs $id/train > $data/train

script/data/retrieve-lines.py $data/sent $id/train > $data/train.sent
script/data/retrieve-lines.py $data/gold-standard $id/train > $data/test.ref
script/data/retrieve-lines.py $data/mrl $id/train > $data/test.mrl
script/data/retrieve-lines.py $data/time $id/train > $data/test.time
cp $id/train $data/train.id

paste $data/test.ref $data/test.mrl $data/test.time > $data/test.mrl.time.ref
script/data/retrieve-lines.py $data/keyword-query.sent $id/train > $data/test.sent
script/data/retrieve-lines.py $data/keyword-query.sent $id/train > $data/test.fullsent

for k in {0..9}; do
    script/data/retrieve-lines.py $data/pairs $id/tune/train-$k > $data/tune/train-$k
    
    cp $id/tune/train-$k $data/tune/train-$k.id
    script/data/retrieve-lines.py $data/gold-standard $id/tune/test-$k > $data/tune/test-$k.ref
    script/data/retrieve-lines.py $data/mrl $id/tune/test-$k > $data/tune/test-$k.mrl
    script/data/retrieve-lines.py $data/time $id/tune/test-$k > $data/tune/test-$k.time
    script/data/retrieve-lines.py $data/sent $id/tune/train-$k > $data/tune/train-$k.sent

    paste $data/tune/test-$k.ref $data/tune/test-$k.mrl $data/tune/test-$k.time > $data/tune/test-$k.mrl.time.ref
   
    script/data/retrieve-lines.py $data/keyword-query.sent $id/tune/test-$k > $data/tune/test-$k.sent
done 

cat $data/sent > $data/sent-all
script/data/make-del-rules.py --trg_factors 1 --symset metadata/geoquery/supervised/symset < $data/sent-all > $data/del-sent-all.rules

#### DONE
