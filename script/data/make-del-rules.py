#!/usr/bin/python
# Script to generate the del rules
#

import sys
import argparse

parser = argparse.ArgumentParser(description="Create an argument Parser")
parser.add_argument('--trg_factors', type=int, required=True)
parser.add_argument('--symset', type=str)
args = parser.parse_args()

ROOT_SYMBOL = "QUERY"

if args.trg_factors != 1 and args.trg_factors != 2:
    raise Exception("Currently can support only 1 or 2 trg_factors")

# Collect all the words in the corpus
words = set()
for line in sys.stdin:
    for word in line.strip().split():
        words.add(word)

sym_set = []
if args.symset:
    with open(args.symset) as symset_fp:
        for line in symset_fp:
            sym_set.append(line.strip())
else:
    sym_set.apend(ROOT_SYMBOL)


# Print the del rule
for word in sorted(list(words)):
    for label in sym_set:
        src = "\"%s\" x0:%s @ %s" % (word, label,label)
        trg = "x0:%s @ %s" % (label,label)
        trgs = " |COL| ".join([trg for i in range(args.trg_factors)])
        print "%s ||| %s ||| del_rule=1" % (src, trgs)

        src = "x0:%s \"%s\" @ %s" % (label,word,label)
        print "%s ||| %s ||| del_rule=1" % (src, trgs)


