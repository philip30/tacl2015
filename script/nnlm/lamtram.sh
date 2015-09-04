#!/bin/bash
set -e

source config.ini

export OPENBLAS_NUM_THREADS=4
mkdir -p $NNLM_DIR/mod
# for f in data/train-*.single; do
# percep40-uadagrad-r50-c4-s100
#for f in data/train-*.single; do
#    f1=`basename $f .single`;
#    f2=${f1/train/test};
#    for layer in percep; do
#        for layersize in 40; do
#            for up in adagrad; do
#                for wordrep in 50; do
#                    for context in 4; do
#                        for lr in 0.1; do
#                            for seed in 100; do
#                                ID="$f1-$layer$layersize-u$up-r$wordrep-c$context-s$seed"
#                                if [[ ! -e mod/$ID.log ]]; then
#                                    echo "~/work/lamtram/src/lamtram/lamtram-train --train_file data/$f1.single --dev_file data/$f2.sent --model_out mod/$ID.mod --layers "$layer:$layersize" --wordrep $wordrep --context $context --update $up --learning_rate $lr &> mod/$ID.log"
#                                    $LAMTRAM/src/lamtram/lamtram-train --train_file data/$f1.single --dev_file data/$f2.sent --model_out mod/$ID.mod --layers "$layer:$layersize" --wordrep $wordrep --context $context --update $up --learning_rate $lr &> mod/$ID.log
#                                fi
#                            done
#                        done
#                    done
#                done
#            done
#        done
#    done
#done

# rec40-uadagrad-r40-c3-s200
for f in $NNLM_DIR/data/train-*.single; do
    f1=`basename $f .single`;
    f2=${f1/train/test};
    for layer in rec; do
        for layersize in 40; do
            for up in adagrad; do
                for wordrep in 40; do
                    for context in 3; do
                        for lr in 0.1; do
                            for seed in 200; do
                                ID="$f1-$layer$layersize-u$up-r$wordrep-c$context-s$seed"
                                if [[ ! -e mod/$ID.log ]]; then
                                    echo "$LAMTRAM/src/lamtram/lamtram-train --train_file $NNLM_DIR/data/$f1.single --dev_file $NNLM_DIR/data/$f2.sent --model_out $NNLM_DIR/mod/$ID.mod --layers "$layer:$layersize" --wordrep $wordrep --context $context --update $up --learning_rate $lr &> $NNLM_DIR/mod/$ID.log"
                                    $LAMTRAM/src/lamtram/lamtram-train --train_file $NNLM_DIR/data/$f1.single --dev_file $NNLM_DIR/data/$f2.sent --model_out $NNLM_DIR/mod/$ID.mod --layers "$layer:$layersize" --wordrep $wordrep --context $context --update $up --learning_rate $lr &> $NNLM_DIR/mod/$ID.log
                                fi
                            done
                        done
                    done
                done
            done
        done
    done
done
