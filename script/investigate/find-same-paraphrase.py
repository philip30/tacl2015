#!/usr/bin/env python

import sys
import argparse
from collections import defaultdict

parser = argparse.ArgumentParser(description="Find paraphrase")
parser.add_argument("--input", type=str, nargs="+")
args = parser.parse_args()

for inp_file in args.input:
    with open(inp_file) as iff:
        dat = defaultdict(lambda:defaultdict(lambda:set()))
        for line in iff:
            line = line.strip().split("\t")
            n = int(line[0])
            
            if line[1] == "Error": 
                continue
            MR, para = line[1].split(" |COL| ")
            correct = line[2] == "1 1"
            dat[n][para].add((MR,correct))
        
        for n, paraphrases in sorted(dat.items(), key=lambda x:x[0]):
            for para, MRs in paraphrases.items():
                if len(MRs) > 1:                    
                    for MR, correct in MRs:
                        print "%s\t%s\t%s\t%s\t%s" % (inp_file, n, para, MR, 1 if correct else 0)
