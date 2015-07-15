#!/usr/bin/python

import sys
import argparse
import re
from collections import defaultdict

parser = argparse.ArgumentParser(description="RNNLM Rescore")
parser.add_argument("--score", type=str, required=True)
parser.add_argument("--input", type=str, required=True)
parser.add_argument("--ini", type=str, required=True)
args = parser.parse_args()

# Read the weight files
weight = defaultdict(lambda:0.0)
with open(args.ini) as ini_file:
    lines = list(ini_file)
    lines = map(lambda x: x.strip(), lines)
    i = 0
    while i < len(lines):
        if lines[i] == "[weight_vals]":
            j=i+1
            while len(lines[j]) != 0:
                key, value = lines[j].split("=")
                weight[key.strip()] = float(value.strip())
                j += 1
            break
        i += 1

# Rescoring
nbest_dict = defaultdict(lambda:[])
with open(args.input) as nbest_file:
    with open(args.score) as score_file:
        for l1, l2 in zip(nbest_file, score_file):
            l1 = l1.strip().split(" ||| ")
            l2 = l2.strip()
            l2 = l2.replace("ll", "nnlm")
            l2 = l2.replace("unk", "nnunk") 
            n = int(l1[0])

            features = {}
            for feat in (l1[-1] + " " + l2).split():
                key, value = feat.split("=")
                if abs(float(value)) > 1e-6:
                    features[key] = float(value)
            
            scores = sum([feat_value * weight[feat_key] for (feat_key, feat_value) in features.items()])
            l1[-2] = scores

            l1[-1] = " ".join(["%s=%f" % (x,y) for x,y in features.items()])
            nbest_dict[n].append(tuple(l1))
            
# Reranking
for n, nbest in nbest_dict.items():
    nbest = sorted(nbest, key=lambda x: x[-2], reverse=True)
    nbest_dict[n] = nbest

# Output
with open(args.input, "w") as out_file:
    for n in sorted(nbest_dict.keys()):
        nbest = nbest_dict[n]
        for line in nbest:
            print >> out_file, " ||| ".join(map(lambda x: str(x),line))
    
