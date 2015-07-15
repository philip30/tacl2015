#!/bin/sh
# Script to execute the data creation
# Philip Arthur (philip.arthur30@gmail.com)

# preparing directory
if [[ ! -d $data ]]; then
echo "Preparing directory.."
mkdir -p $data
# preparing Gold-standard
echo "Making Gold Standard.."
script/data/extract-logic.py < $inp > $data/mrl 2> $data/sent  

# whether to simulate keyword input or not
if [[ $stopword = true ]]; then
    script/data/simulate-keyword.py --stopword metadata/stopword-list.txt $shuffle < $data/sent > $data/sent.keyword
fi

# Preparing query (for making gold-standard) ?
script/data/query.py "execute_query" < $data/mrl > $data/query

# Stemming and which-what normalization
script/data/stem.pl < $data/sent > $data/sent.stem
sed -i 's/which/what/g' $data/sent$p_extract_stem
sed -i 's/which/what/g' $data/sent

if [[ $stopword = true ]]; then 
    script/data/stem.pl < $data/sent.keyword > $data/sent.keyword$p_extract_stem
    sed -i 's/which/what/g' $data/sent.keyword$p_extract_stem
    sed -i 's/which/what/g' $data/sent.keyword
fi

# Remerge the sent-mrl into "parse(sent,mrl)." form.
script/data/merge-logic.py $data/sent$p_extract_stem $data/mrl > $data/pairs

if [[ $stopword = true ]]; then
    script/data/merge-logic.py $data/sent.keyword$p_extract_stem $data/mrl > $data/pairs.keyword
fi 

# We already run the GS and time in our computer, you can rerun the time to adjust to your computer!
cp metadata/geoquery/gold-standard $data
cp metadata/geoquery/time $data

# Begin to map the data.
echo "Mapping id to sentence.."
# FOR EACH RUN
for i in {0..0}; do
# FOR EACH FOLD
for j in {0..9}; do
    mkdir -p $data/run-$i/fold-$j/tune
    $extractor $data/pairs $id/run-$i/fold-$j/train > $data/run-$i/fold-$j/train
    if [[ $stopword = true ]]; then
         $extractor $data/pairs.keyword $id/run-$i/fold-$j/train > $data/run-$i/fold-$j/train.keyword
    fi
    
    $extractor $data/sent$p_extract_stem $id/run-$i/fold-$j/train > $data/run-$i/fold-$j/train.sent
    $extractor $data/gold-standard $id/run-$i/fold-$j/test > $data/run-$i/fold-$j/test.ref
    $extractor $data/mrl $id/run-$i/fold-$j/test > $data/run-$i/fold-$j/test.mrl
    $extractor $data/time $id/run-$i/fold-$j/test > $data/run-$i/fold-$j/test.time
    cp $id/run-$i/fold-$j/train $data/run-$i/fold-$j/train.id
    
    paste $data/run-$i/fold-$j/test.ref $data/run-$i/fold-$j/test.mrl $data/run-$i/fold-$j/test.time > $data/run-$i/fold-$j/test.mrl.time.ref
    if [[ $stopword = true ]]; then
        $extractor $data/sent.keyword$p_extract_stem $id/run-$i/fold-$j/test > $data/run-$i/fold-$j/test.sent
    else
        $extractor $data/sent$p_extract_stem $id/run-$i/fold-$j/test > $data/run-$i/fold-$j/test.sent
    fi
    $extractor $data/sent$p_extract_stem $id/run-$i/fold-$j/test > $data/run-$i/fold-$j/test.fullsent
    
    for k in {0..9}; do
        $extractor $data/pairs $id/run-$i/fold-$j/tune/train-$k > $data/run-$i/fold-$j/tune/train-$k
        if [[ $stopword = true ]]; then
            $extractor $data/pairs.keyword $id/run-$i/fold-$j/tune/train-$k > $data/run-$i/fold-$j/tune/train-$k.keyword
        fi
        
        cp $id/run-$i/fold-$j/tune/train-$k $data/run-$i/fold-$j/tune/train-$k.id
        $extractor $data/gold-standard $id/run-$i/fold-$j/tune/test-$k > $data/run-$i/fold-$j/tune/test-$k.ref
        $extractor $data/mrl $id/run-$i/fold-$j/tune/test-$k > $data/run-$i/fold-$j/tune/test-$k.mrl
        $extractor $data/time $id/run-$i/fold-$j/tune/test-$k > $data/run-$i/fold-$j/tune/test-$k.time
        $extractor $data/sent$p_extract_stem $id/run-$i/fold-$j/tune/train-$k > $data/run-$i/fold-$j/tune/train-$k.sent

        paste $data/run-$i/fold-$j/tune/test-$k.ref $data/run-$i/fold-$j/tune/test-$k.mrl $data/run-$i/fold-$j/tune/test-$k.time > $data/run-$i/fold-$j/tune/test-$k.mrl.time.ref
       
        if [[ $stopword = true ]]; then
            $extractor $data/sent.keyword$p_extract_stem $id/run-$i/fold-$j/tune/test-$k > $data/run-$i/fold-$j/tune/test-$k.sent
        else
            $extractor $data/sent$p_extract_stem $id/run-$i/fold-$j/tune/test-$k > $data/run-$i/fold-$j/tune/test-$k.sent
        fi
    done 
done # fold
done # run
echo "Making DEL-rule"
cat $data/sent$p_extract_stem $data/sent > $data/sent-all
script/data/make-del-rules.py --trg_factors 1 --symset metadata/geoquery/supervised/symset < $data/sent-all > $data/del-sent-all.rules
rm $data/sent-all
echo "DONE!"
else
    echo "Director $data is exist"
fi

