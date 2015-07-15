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
parser.add_argument('-weight', type=str, required=True)
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

lines = []
with open(args.input) as ini_file:
    lines = ini_file.readlines()
    lines = map(lambda x: x.strip(), lines)

ini = create_ini(lines)


weight_lines = []
with open(args.weight) as ini_file:
    weight_lines = ini_file.readlines()
    weight_lines = map(lambda x: x.strip(), weight_lines)

weight_ini = create_ini(weight_lines)

ini["weight_vals"] = weight_ini["weight_vals"]

# printing
for k, v in ini.items():
    print "["+k+"]"
    for i in sorted(v):
        print i
    print ""


