#!/usr/bin/python
# script to Merge several ini into one ini
# Usage merge-ini.py -i [INPUT...] -tm [TM]
# Philip Arthur philip.arthur30@gmail.co

import sys
import os
import argparse
from collections import defaultdict

parser = argparse.ArgumentParser(description="Merge ini")
parser.add_argument('-i', type=str, dest='input', required=True)
parser.add_argument('-tm', type=str, required=True)
args = parser.parse_args()

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

lines = []
with open(args.input) as ini:
    lines = ini.readlines()
    lines = map(lambda x: x.strip(), lines)

ini = create_ini(lines)
ini['tm_file'] = [args.tm]

# printing
for k, v in ini.items():
    print "["+k+"]"
    for i in sorted(v):
        print i
    print ""


