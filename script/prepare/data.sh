#!/bin/bash
# SCRIPT to extract data given ID 
# run prepare-id.sh first!
# Philip Arthur (philip.arthur30@gmail.com)

set -e # exit immediately when error

# Loading configuration
source config.ini

data=data/full-question
inp=metadata/geoquery/geoqueries880
id=id/wong-split
extractor=script/data/retrieve-lines.py
stopword=
shuffle=

source script/prepare/prepare-exec.sh

