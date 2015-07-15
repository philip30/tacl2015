#!/usr/bin/python
# script to Merge several ini into one ini
# Usage merge-ini.py -i [INPUT...] -tm [TM]
# Philip Arthur philip.arthur30@gmail.co

import sys
import os
import argparse
from collections import defaultdict

parser = argparse.ArgumentParser(description="Merge ini")
parser.add_argument('-i', nargs='+', type=str, dest='input', default=[], required=True)
parser.add_argument('-best', nargs='+', type=str, dest='best', default=[], required=True)
parser.add_argument('-method', choices=['avg','best1','best5','weighted'],default='avg')
parser.add_argument('-tm', type=str, required=True)
args = parser.parse_args()

if len(args.input) != len(args.best):
    raise Exception("len(ini) != len(best)")

# Parse ini file into a map
def create_ini(lines):
    i = 0
    map_ret = {}
    while i < len(lines):
        if lines[i].startswith("["):
            k = lines[i][1:-1]
            i+= 1
            attribute = []
            while i < len(lines) and len(lines[i]) != 0:
                attribute.append(lines[i])
                i+= 1
            map_ret[k] = attribute
        else:
           i+= 1
    return map_ret 

# Parse the weight!
def parse_weight(weights):
    ret_w = defaultdict(lambda:0)
    for w in weights:
        k, value = w.split("=")
        ret_w[k] = value
    return ret_w

def average(weights):
    ret = defaultdict(lambda:0)
    for acc, w in weights:
        for k, value in w.items():
            ret[k] += float(value)

    # normalization by n_fold
    for k,v in ret.items():
        ret[k] = v / len(weights)
    return ret
 

def best1(weights):
    # the best accuracy weight
    return weights[0][1] 

def best5(weights):
    ret = defaultdict(lambda:0)
    for (acc, w), i in zip(weights, range(5)):
        for k, value in w.items():
            ret[k] += float(value)
    for k,v in ret.items():
        ret[k] = v / 5
    return ret

def weighted(weights):
    ret = defaultdict(lambda:0)
    denom = float(0)
    for acc, w in weights:
        for k, value in w.items():
            ret[k] += acc * float(value)
        denom += float(acc)
    for k, v in ret.items():
        ret[k] = v / denom
    return ret

merged_ini = {}
weights = []
for f, b in zip(args.input, args.best):
    # read 1 ini
    with open(f) as ini:
        lines = ini.readlines()
        lines = map(lambda x: x.strip(), lines)
        inmerged_iniap = create_ini(lines)
        for key, value in inmerged_iniap.items():
            # now merging them together
            if key != "weight_vals":
                if key not in merged_ini:
                    merged_ini[key] = value
                # except the TM and weight every one else should be the same
                elif value != merged_ini[key] and key != 'tm_file':
                    raise Exception("Error value in ini does not uniform %s: %s with %s" % (key, merged_ini[key], value))
    with open(b) as best:
        line = best.readline().strip()[len("Best: "):]
        weight, acc = line.split(" => ")
        weight = parse_weight(weight.split(" "))
        weights.append((float(acc), weight))

# Sort by its accuracy
weights = sorted(weights, key=lambda x: x[0], reverse=True)

# merging weight
weight_final = None
if args.method == "avg": weight_final = average(weights)
elif args.method == "best1": weight_final = best1(weights)
elif args.method == "best5": weight_final = best5(weights)
elif args.method == "weighted": weight_final = weighted(weights)
else: raise Exception("Unknown weight merge method = %s" % (args.method))

merged_ini['tm_file'] = [args.tm]
merged_ini['weight_vals'] = [n for n in (['='.join([k,str(v)]) for k,v in weight_final.items()])]

# printing
for k, v in merged_ini.items():
    print "["+k+"]"
    for i in sorted(v):
        print i
    print ""


