#!/bin/bash
# SCRIPT to extract all the LMs need for the experiment
# run prepare-data.sh first!
# Philip Arthur (philip.arthur30@gmail.com)

set -e # exit immediately when error
set -o xtrace

# Loading configuration
source config.ini

p_travatar="-travatar $TRAVATAR"
p_srilm="-srilm $SRILM"
p_stanford_parser="-stanford-parser $STANFORD_JAR"
p_lm="$p_travatar $p_srilm $p_stanford_parser"
data="data/full-question"
p_prefix="lm-create"
p_stem="-stem"

if [ ! -d lm ]; then
    mkdir -p lm
fi

P_NEWS=
P_QUESTIONS=
P_GEO=true
P_INTERPOLATE=

if [[ $P_NEWS = true ]]; then
echo "=========== Preparing NEWS 2009 ============="
script/data/make-lm.pl $p_stem $p_lm -prefix "lm-news" -working-dir $p_prefix/news2009 -input $NEWS
fi

if [[ $P_QUESTIONS = true ]]; then
echo "=========== Preparing QUESTIONS ============="
script/data/make-lm.pl $p_stem $p_lm -prefix "lm-questions" -working-dir $p_prefix/questions -input $QUESTIONS
fi

if [[ $P_GEO = true ]]; then
echo "=========== Preparing GEOQUERY =============="
# For every fold
for j in ${NUM_FOLD[*]}; do
    mkdir -p lm/geoquery/fold-$j
    script/data/make-lm.pl $p_stem $p_lm -prefix "lm-geo" -working-dir $p_prefix/geoquery/fold-$j -input $data/run-0/fold-$j/train.sent
    for k in ${NUM_FOLD[*]}; do
        script/data/make-lm.pl $p_stem $p_lm -prefix "lm-geo" -working-dir $p_prefix/geoquery/fold-$j/tune-$k -input $data/run-0/fold-$j/tune/train-$k.sent
    done
done
fi

if [[ $P_INTERPOLATE = true ]]; then
echo "=========== Preparing Interpolated GEOQUERY =============="
for i in ${NUM_RUN[*]}; do
# For every fold
#for j in ${NUM_FOLD[*]}; do
    j=$1
    script/data/interpolate-lm.pl --tuning $data/sent.stem --name $p_prefix/geoquery/fold-$j/lm-geo-news.arpa -lm $p_prefix/geoquery/fold-$j/lm-geo.arpa,$p_prefix/news2009/lm-news.arpa --srilm $SRILM
    script/data/interpolate-lm.pl --tuning $data/sent.stem --name $p_prefix/geoquery/fold-$j/lm-geo-questions.arpa -lm $p_prefix/geoquery/fold-$j/lm-geo.arpa,$p_prefix/questions/lm-questions.arpa --srilm $SRILM
    script/data/interpolate-lm.pl --tuning $data/sent.stem --name $p_prefix/geoquery/fold-$j/lm-geo-all.arpa -lm $p_prefix/geoquery/fold-$j/lm-geo.arpa,$p_prefix/questions/lm-questions.arpa,$p_prefix/news2009/lm-news.arpa --srilm $SRILM
    $TRAVATAR/src/kenlm/lm/build_binary -i $p_prefix/geoquery/fold-$j/lm-geo-news.arpa $p_prefix/geoquery/fold-$j/lm-geo-news.blm
    $TRAVATAR/src/kenlm/lm/build_binary -i $p_prefix/geoquery/fold-$j/lm-geo-questions.arpa $p_prefix/geoquery/fold-$j/lm-geo-questions.blm
    $TRAVATAR/src/kenlm/lm/build_binary -i $p_prefix/geoquery/fold-$j/lm-geo-all.arpa $p_prefix/geoquery/fold-$j/lm-all.blm
#done
done
fi
