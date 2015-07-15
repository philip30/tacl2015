#!/usr/bin/python
# Script for spliting the training data to 10 fold for tuning
# Usage : split-tune.py [TRAINING_DATA] [OUTPUT_PREFIX]
# Philip Arthur [philip.arthur30@gmail.com]

import sys
import random

FOLD = 10

inp = []
with open(sys.argv[1]) as input_file:
    for line in input_file:
        line = line.strip()
        inp.append(line)

# shuffle
random.shuffle(inp)

# Generating the fold
portion = int(len(inp)/FOLD)
parts = []

for i in range(0,FOLD):
    parts.append(inp[i*portion : min((i+1)*portion, len(inp))])

remainder = len(inp) % FOLD
for i in range(remainder):
    parts[i].append(inp[-remainder])

# Printing the fold
for i in range(FOLD):
    test = parts[i]
    train = []
    for j in range(FOLD):
        if i != j:
            for t_line in parts[j]:
                train.append(t_line)
    with open(sys.argv[2] + "/train-%d" % (i),"w") as train_fp:
        for line in train:
            print >> train_fp, line
    with open(sys.argv[2] + "/test-%d" % (i),"w") as test_fp:
        for line in test:
            print >> test_fp, line

    
