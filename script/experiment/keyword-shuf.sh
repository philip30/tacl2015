#!/bin/bash
# Script for running baseline experiment
# by Philip Arthur
# Usage: Just run it! But don't forget to configure it

set -e                      # exit when error
set -o xtrace               # debug mode on

# Loading Global Configuration
source config.ini

experiment_dir="$BASE_DIR/shuffled/direct"
trg_factors=1
data="data/keyword-shuffle"
p_keyword_train=".keyword"
direct=true

source script/experiment/part/parameters.sh
source script/experiment/part/execute.sh
