#!/bin/bash
# Script for running baseline experiment
# by Philip Arthur
# Usage: Just run it! But don't forget to configure it

set -e                      # exit when error
set -o xtrace               # debug mode on

# Loading Global Configuration
source script/closed/config.ini

experiment_dir="$BASE_DIR/shuffled/baseline"
data="data/closed"

# Language Model
p_lm=
GEO_LM=

source config/keyword.config
source config/shuffle.config
source config/nnlm.config
source script/closed/parameters.sh
source script/closed/execute.sh
