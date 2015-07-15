#!/usr/bin/python

import sys
import argparse
import random

argparse = argparse.ArgumentParser(description="Human Para")
argparse.add_argument('--keyword', type=str, required=True)
argparse.add_argument('--input', nargs='+', required=True, default=[])
argparse.add_argument('--top', type=int,default=100)
args = argparse.parse_args()

SENT_MAP = 2

test_set = {}
for i in range(10): # For each Fold 
    question_f = open("%s/run-0/fold-%i/test.fullsent" % (args.keyword, i))
    keyword_f = open("%s/run-0/fold-%i/test.sent" % (args.keyword, i))
    for j, (q, k) in enumerate(zip(question_f, keyword_f)):
        q, k = (q.strip(), k.strip())
        test_set[i,j] = [q,k, {}]


for i in range(10):
    for output_f in args.input:
        if output_f.endswith("direct"):
            continue
        with open(output_f + "/run-0/fold-%i/test/out.txt" % (i)) as of:
            for j, line in enumerate(of):
                line = line.strip().split(" |COL| ")[0]
                test_set[i,j][SENT_MAP][output_f] = line


keys = [k for k in test_set.keys()]
random.shuffle(keys)

count = 0
for key in keys:
    (q, k, outputs) = test_set[key]
    if any([len(out) == 0 for out in outputs.values()]):
        continue
    if count >= args.top:
        break
    print "Original Question:", q
    print "Keyword version  :", k
    for f, output in sorted(outputs.items()):
        print f,
        print " ".join(["" for x in range(50-len(f))]),
        print output
    print ""
    count += 1

