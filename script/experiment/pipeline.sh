#!/bin/bash
# Script for running baseline experiment
# by Philip Arthur
# Usage: Just run it! But don't forget to configure it

set -e                      # exit when error
set -o xtrace               # debug mode on

# Loading Global Configuration
source config.ini

experiment_dir="$BASE_DIR/pipeline"
trg_factors=1
data="data/full-question"
data_question="data/full-question"
data_keyword="data/keyword-shuffle"
nl_mrl_model="fold-normal/baseline"

source config/nnlm.config
source script/experiment/part/parameters.sh
source script/experiment/part/execute-pipeline.sh
