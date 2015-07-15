#!/usr/bin/python

import sys
import argparse

parser = argparse.ArgumentParser(description="Compare N-Best")
parser.add_argument("--baseline", type=str, required=True)
parser.add_argument("--systems", nargs="+",type=str, required=True)
args = parser.parse_args()

def read_nbest(f):
    ret = {}
    with open(f) as file_input:
        for line in file_input:
           n, line, correct = line.strip().split("\t")
           if n not in ret:
               ret[n] = (line, correct,f.split("/")[3])
    return ret

baseline = read_nbest(args.baseline)
systems = map(read_nbest, args.systems)

for i in sorted(baseline.keys()):
    if all(i in x for x in systems) and any(baseline[i][1] != x[i][1] for x in systems):
        print "#%s" % i
        for sys in ([baseline] + systems):
            print "%s\t%s %s" % (sys[i][2], sys[i][1], sys[i][0])
        print ""
        
