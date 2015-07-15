#!/usr/bin/python
# Philip Arthur (philip.arthur30@gmail.com)
# March, 11th 2015

import sys
import argparse

argparser = argparse.ArgumentParser(description="Merging fold and creating reference file")
argparser.add_argument("--nbest", nargs="+", type=str, required=True)
argparser.add_argument("--nbest_out", type=str, required=True)
argparser.add_argument("--ref", nargs="+", type=str, required=True)
argparser.add_argument("--ref_out", type=str, required=True)
args = argparser.parse_args()

nbest_file_str = args.nbest
ref_file_str = args.ref

if len(nbest_file_str) != len(ref_file_str):
    raise Exception("Length nbest != length reference")

# Merging nbest from different fold together, also creating the corresponding ref file
offset = 0
ref_out = open(args.ref_out, "w")
nbest_out = open(args.nbest_out, "w")
for nbest_str, r_str in zip(nbest_file_str, ref_file_str):
    with open(nbest_str) as nbest_file:
        for line in nbest_file:
            line = line.strip().split(" ||| ")
            n = int(line[0])
            line[0] = str(n + offset)
            print >> nbest_out, " ||| ".join(line)
    with open(r_str) as ref_file:
        for i, line in enumerate(ref_file):
            line = line.strip()
            print >> ref_out, line
        offset += (i+1)

ref_out.close()
nbest_out.close()

