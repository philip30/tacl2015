#!/usr/bin/python

import sys
import argparse
from collections import defaultdict

argparser = argparse.ArgumentParser(description="Make Report")
argparser.add_argument("--reduct", type=str, required=True)
argparser.add_argument("--input", type=str, required=True)
argparser.add_argument("--reference", type=str, required=True)
argparser.add_argument("--stat", type=str, required=True)
argparser.add_argument("--mrl", type=str, required=True)
argparser.add_argument("--paraphrase", type=str)
args = argparser.parse_args()

REDUCT = 0
STAT = 1

def read_file(f):
    ret = []
    with open(f) as f_p:
        for line in f_p:
            ret.append(line.strip())
    return ret

inp = read_file(args.input)
ref = read_file(args.reference)
mrl = read_file(args.mrl)
paraphrase = None

if args.paraphrase:
    paraphrase = read_file(args.paraphrase)

data = defaultdict(lambda:([],[]))
i_map = {}


with open(args.reduct) as red_fp:
    for (i, line) in enumerate(red_fp):
        line = line.strip()
        n, red = line.split("\t")
        i_map[i] = int(n)
        data[int(n)][REDUCT].append(red) 

with open(args.stat) as stat_fp:
    for (i, line) in enumerate(stat_fp):
        line = line.strip()
        data[i_map[i]][STAT].append(line == "1 1")

for i, (inp, ref, mrl) in enumerate(zip(inp,ref,mrl)):
    print "%d\t%s" % (i, inp)
    print "Correct MRL  :", mrl

    if paraphrase:
        print "Correct Para :", paraphrase[i]

    print ref.split("\t")[0], "\n"
    for red, stat in zip(data[i][REDUCT], data[i][STAT]):
        print "[%d]" % (1 if stat else 0) , red
    
    print ""
            

