#!/bin/bash
# Script for running baseline experiment
# by Philip Arthur
# Usage: Just run it! But don't forget to configure it

set -e                      # exit when error
set -o xtrace               # debug mode on

# Loading Global Configuration
source config.ini

experiment_dir="$BASE_DIR/shuffled/baseline"
data="data/keyword-shuffle"

# Language Model
p_lm=
GEO_LM=

source config/keyword.config
source config/shuffle.config
source config/nnlm.config
source script/experiment/part/parameters.sh
source script/experiment/part/execute.sh
