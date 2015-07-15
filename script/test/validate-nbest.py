#!/usr/bin/python
# Script to insert empty nbest list into an empty nbest
# Usage: validate-nbest.py < [NBEST_LIST] > [Validated n-best list]

import sys
import argparse
from collections import defaultdict

parser= argparse.ArgumentParser(description="Validate N-Best")
parser.add_argument('-n', type=int, dest='length', required=True)
args = parser.parse_args()

nbest = defaultdict(lambda:[])
for line in sys.stdin:
    line = line.strip()
    n, answer, score, feature = line.split(" ||| ")
    nbest[int(n)].append(line)

for i in range(args.length):
    if i not in nbest:
        print "%d |||  ||| -100 ||| EMPTY=1" % (i)
    else:
        for line in nbest[i]:
            print line

