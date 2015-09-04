#!/usr/bin/env python

import sys
import argparse
from random import shuffle

# Arguments
parser = argparse.ArgumentParser()
parser.add_argument("--input", type=str, required=True)
parser.add_argument("--stopword", type=str, required=True)
args = parser.parse_args()

# Data structure
stopwords=set()

# Reading stopword
for line in open(args.stopword):
    stopwords.add(line.strip())

# Processing line by line
for line in open(args.input):
    cols = line.strip().split()
    if len(cols) >= 1:
        if cols[-1] == '?':
            cols = cols[:-1]
        filtered = filter(lambda x: x not in stopwords, cols)
        if len(filtered) == 0:
            filtered = cols
        shuffle(filtered)
    print " ".join(filtered)

