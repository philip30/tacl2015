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
stopword=
shuffle=
test_inp=metadata/geoquery/geokey.sent

source script/prepare/prepare-exec-real.sh

