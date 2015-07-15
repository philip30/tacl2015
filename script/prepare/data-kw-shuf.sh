#!/bin/bash
# SCRIPT to extract data given ID 
# Philip Arthur (philip.arthur30@gmail.com)

set -e # exit immediately when error

# Loading configuration
source config.ini

data=data/keyword-shuffle
inp=metadata/geoquery/geoqueries880
id=id/wong-split
extractor=script/data/retrieve-lines.py
stopword=true
shuffle="--shuffle"

source script/prepare/prepare-exec.sh

