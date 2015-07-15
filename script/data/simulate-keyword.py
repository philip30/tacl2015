#!/usr/bin/python

import sys
import argparse
import random

parser = argparse.ArgumentParser(description="Simulate Keyowrd")
parser.add_argument('--shuffle', action="store_true")
parser.add_argument('--stopword', type=str, required=True)
args = parser.parse_args()

stopword_list = set()
with open(args.stopword) as swfp:
    for line in swfp:
        line = line.strip()
        if line.startswith("#"):
            continue
        stopword_list.add(line)

for inp in sys.stdin:
    inp = inp.strip().split()
    inp = filter(lambda x: x not in stopword_list, inp)
    
    if args.shuffle:
        random.shuffle(inp)

    print " ".join(inp)
