#!/bin/bash

# Preparation
if [[ -d $experiment_dir && ( ! $force = true ) ]]; then 
    echo "Directory $experiment_dir exists"
    exit 1
fi


if [[ $TRAIN = true ]]; then
    script/train/intersect-para.py --input $data_old_model --paraphrase $data_para_model --output $experiment_dir
fi

# For every run
for i in ${NUM_RUN[*]}; do
# For every fold
for j in ${NUM_FOLD[*]}; do
    mkdir -p $experiment_dir/run-$i/fold-$j/tune
    
    # NNLM FLAG
    if [[ $NNLM = true ]]; then
        p_nnlm="-nnlm $NNLM_DIR/mod/train-$j-$NNLM_MODEL.mod"
    fi

    # Training
    train_inp=$data/run-$i/fold-$j/train$p_keyword_train
    train_dir=$experiment_dir/run-$i/fold-$j/train
   
    # Tuning
    tune_dir=$experiment_dir/run-$i/fold-$j/tune
    if [[ $TUNE = true ]]; then
        tune_ini_dir=$experiment_dir/run-$i/fold-$j/tune-ini
        mkdir -p $tune_ini_dir
        
        p_ini="-fold-config "

        for k in ${NUM_FOLD_TUNE[*]}; do # 10-cross fold validation
            # First generate the training with 90% data of training
            tune_train_inp=$data/run-$i/fold-$j/tune/train-$k$p_keyword_train
            tune_train_dir=$tune_dir/train-$k
            tune_tune_dir=$tune_dir/tune-$k
            tune_src=$data/run-$i/fold-$j/tune/test-$k.sent
            tune_mrl=$data/run-$i/fold-$j/tune/test-$k.mrl
            tune_ref=$data/run-$i/fold-$j/tune/test-$k.ref
            tune_config=$tune_train_dir/model/travatar.ini

            # Assume that FOLD validation if true here
            echo "src=$tune_src" > $tune_ini_dir/config-$k.ini
            echo "ref=$tune_mrl.time.ref" >> $tune_ini_dir/config-$k.ini
            echo "tm_file=$tune_train_dir/model/rule-table.gz" >> $tune_ini_dir/config-$k.ini
            
            p_ini=$p_ini$tune_ini_dir/config-$k.ini","
            # END of Assumption
        done
        script/run-tune-allfold.pl -working-dir $tune_dir/tune-travatar -travatar-config $train_dir/model/travatar.ini $p_ini $p_tune $p_nnlm 
        cp $tune_dir/tune-travatar/travatar.ini $tune_dir/travatar.ini
        sed -i '/=0$/d' $tune_dir/travatar.ini
    fi

    # Testing
    if [[ $TEST = true ]]; then
        test_dir=$experiment_dir/run-$i/fold-$j/test
        test_inp=$data/run-$i/fold-$j/test.sent
        test_mrl=$data/run-$i/fold-$j/test.mrl
        test_ref=$data/run-$i/fold-$j/test.ref
        test_config=$tune_dir/travatar.ini
        script/run-test.pl -working-dir $test_dir -travatar-config $test_config -src $test_inp -ref $test_mrl.time.ref $p_test
        
        if [[ $NNLM = true ]]; then
            script/run-test.pl -working-dir $test_dir-nnlm -travatar-config $tune_dir/tune-travatar/travatar.ini -src $test_inp -ref $ref $test_mrl.time.ref $p_test $p_nnlm -nnlm-config $tune_dir/tune-travatar/travatar-nnlm.ini
        fi
    
        # paraphrase argument?
        if [[ $trg_factors -eq "2" ]]; then
            paraphrase="--paraphrase $data/run-$i/fold-$j/test.fullsent"
        fi
        
        # Creating Report
        script/test/make-report.py --reduct $test_dir/nbest.reduct --input $test_inp --reference $test_ref --mrl $test_mrl --stat $test_dir/nbest.stats $paraphrase > $test_dir/test.report
        
        if [[ $NNLM = true ]]; then
            script/test/make-report.py --reduct $test_dir-nnlm/nbest.reduct --input $test_inp --reference $test_ref --mrl $test_mrl --stat $test_dir-nnlm/nbest.stats $paraphrase > $test_dir-nnlm/test.report
        fi
    fi
done # fold
if [[ $TEST = true ]]; then
    # Averaging every_fold result
    script/test/calculate-score.py -i $experiment_dir/run-$i/fold-*/test/nbest.stats.res -gs $data/run-$i/fold-*/test.ref > $experiment_dir/run-$i/test.result
    cat $experiment_dir/run-$i/test.result
    if [[ $NNLM = true ]]; then
        script/test/calculate-score.py -i $experiment_dir/run-$i/fold-*/test-nnlm/nbest.stats.res -gs $data/run-$i/fold-*/test.ref > $experiment_dir/run-$i/test-nnlm.result
        cat $experiment_dir/run-$i/test-nnlm.result
    fi
fi
done # run


