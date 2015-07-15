#!/usr/bin/env python

import sys
import argparse
from collections import defaultdict

parser = argparse.ArgumentParser(description="Calculate Unique")
parser.add_argument("--input", nargs="+", required=True, type=str)
parser.add_argument("--total", type=int, required=True)
parser.add_argument("--delimiter", type=str, default="\t")
args = parser.parse_args()

if args.total <= 0:
    raise Exception("--total should > 0")

total = 0
for inp_str in args.input:
    with open(inp_str) as inp_file:
        data = defaultdict(lambda:set())
        for line in inp_file:
            line = line.strip().split(args.delimiter)
            MR = line[1].split(" |COL| ")[0]
            data[line[0]].add(MR)

        for val_set in data.values():
#            print len(val_set)
            total += len(val_set)

print float(total) / args.total


