#!/bin/bash
# Script for running baseline experiment
# by Philip Arthur
# Usage: Just run it! But don't forget to configure it

set -e                      # exit when error
set -o xtrace               # debug mode on

# Loading Global Configuration
source config.ini

experiment_dir="$BASE_DIR/para-augment"
trg_factors=1
data="data/keyword-shuffle"
data_para_model="para-augment/para-model/model/rule-table.gz"
data_old_model="fold-normal/shuffled/question"

source config/keyword.config
source config/nnlm.config
source script/experiment/part/parameters.sh
source script/experiment/part/execute-paraaugment.sh
