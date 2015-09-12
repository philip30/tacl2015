#!/bin/bash

TRAINING_OPTIONS="-travatar_dir $TRAVATAR -bin_dir $GIZA -threads $threads -method hiero"

# Preparation
if [[ -d $experiment_dir && ( ! $force = true ) ]]; then 
    echo "Directory $experiment_dir exists"
    exit 1
fi

# For every run
for i in ${NUM_RUN[*]}; do
# For every fold
for j in ${NUM_FOLD[*]}; do
    mkdir -p $experiment_dir/run-$i/fold-$j

    # NNLM FLAG
    if [[ $NNLM = true ]]; then
        p_nnlm="-nnlm $NNLM_DIR/mod/train-$j-$NNLM_MODEL.mod"
    fi

    # Training
    train_inp=$data/run-$i/fold-$j/train$p_keyword_train
    train_dir=$experiment_dir/run-$i/fold-$j/train

    if [[ $TRAIN = true ]]; then
        if [ -d $train_dir ]; then
            rm -r $train_dir
        fi
        if [[ $GEO_LM ]]; then
            p_lm_exec="-lm_file lm/geoquery/fold-$j/$p_lm"
            p_lm_exec+=".blm"
        else
            p_lm_exec=$p_lm
        fi 
        $TRAVATAR/script/train/train-travatar.pl -work_dir $train_dir $p_lm_exec -src_file $data_keyword/run-$i/fold-$j/train.kw -trg_file $data_question/run-$i/fold-$j/train.sent $TRAINING_OPTIONS
    fi
    
    # Tuning
    tune_dir=$experiment_dir/run-$i/fold-$j/tune
    tune_ini_dir=$experiment_dir/run-$i/fold-$j/tune-ini
    p_ini="-fold-config "
    if [[ $TUNE = true ]]; then
        if [ -d $tune_dir ]; then
            rm -r $tune_dir
        fi
        mkdir -p $tune_dir
        mkdir -p $tune_ini_dir

        for k in ${NUM_FOLD_TUNE[*]}; do # 10-cross fold validation
            # First generate the training with 90% data of training
            tune_train_inp=$data/run-$i/fold-$j/tune/train-$k$p_keyword_train
            tune_train_dir=$tune_dir/train-$k
            tune_tune_dir=$tune_dir/tune-$k
            tune_src=$data_keyword/run-$i/fold-$j/tune/test-$k.sent
            tune_trg=$data_question/run-$i/fold-$j/tune/test-$k.sent
            tune_config=$tune_train_dir/model/travatar.ini

            # Assume that Fold validation is true
            echo "src=$tune_src" > $tune_ini_dir/config-$k.ini
            echo "ref=$tune_trg" >> $tune_ini_dir/config-$k.ini
            echo "tm_file=$tune_train_dir/model/rule-table.gz" >> $tune_ini_dir/config-$k.ini
            echo "glue=$tune_train_dir/model/glue-rules" >> $tune_ini_dir/config-$k.ini

            if [[ $GEO_LM_TUNE = true ]] ; then
                echo "lm_file=lm/geoquery/fold-$j/tune-$k/$p_lm.blm" >> $tune_ini_dir/config-$k.ini
            fi
            p_ini=$p_ini$tune_ini_dir/config-$k.ini","
            # End of Assumption
            
            if [[ $GEO_LM_TUNE ]]; then
                p_lm_exec="-lm-file lm/geoquery/fold-$j/tune-$k/$p_lm"
                p_lm_exec+=".blm"
            fi

            $TRAVATAR/script/train/train-travatar.pl -work_dir $tune_train_dir -lm_file lm/questions/lm-questions.blm -src_file $data_keyword/run-$i/fold-$j/tune/train-$k.kw -trg_file $data_question/run-$i/fold-$j/tune/train-$k.sent $TRAINING_OPTIONS
        done
        script/pipeline/run-tune-allfold.pl -working-dir $tune_dir/tune-travatar -travatar-config $train_dir/model/travatar.ini $p_ini $p_tune $p_nnlm 
        cp $tune_dir/tune-travatar/travatar.ini $tune_dir/travatar.ini
        sed -i '/=0$/d' $tune_dir/travatar.ini
    fi

    # Testing
    if [[ $TEST = true ]]; then
        test_dir=$experiment_dir/run-$i/fold-$j/test
        test_inp=$data_keyword/run-$i/fold-$j/test.sent
        test_mrl=$data/run-$i/fold-$j/test.mrl
        test_ref=$data/run-$i/fold-$j/test.ref
        test_para=$data/run-$i/fold-$j/test.fullsent
        test_config=$tune_dir/travatar.ini

        script/pipeline/run-test.pl -working-dir $test_dir -kwnl-config $tune_dir/tune-travatar/travatar.ini -nlmrl-config $nl_mrl_model/run-$i/fold-$j/tune/tune-travatar/travatar.ini -src $test_inp -ref $test_mrl.time.ref $p_test $p_nnlm -nnlm-config $tune_dir/tune-travatar/travatar-nnlm.ini -para-ref $test_para
        
        # Creating Report
        script/test/make-report.py --reduct $test_dir/nbest.reduct --input $test_inp --reference $test_ref --mrl $test_mrl --stat $test_dir/nbest.stats $paraphrase > $test_dir/test.report
    fi
done # fold
if [[ $TEST = true ]]; then
    # Averaging every_fold result
    script/test/calculate-score.py -i $experiment_dir/run-$i/fold-*/test/nbest.stats.res -gs $data/run-$i/fold-*/test.ref > $experiment_dir/run-$i/test.result
    cat $experiment_dir/run-$i/test.result
fi
done # run


