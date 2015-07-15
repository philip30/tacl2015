#!/usr/bin/python
# Script to merge NL - MRL to parse(NL, MRL)
# Usage merge-logic.py [NL] [MRL]
# Philip Arthur

import sys

with open(sys.argv[1]) as nl_fp:
    with open(sys.argv[2]) as mrl_fp:
        for l1, l2 in zip(nl_fp, mrl_fp):
            l1 = l1.strip()
            l2 = l2.strip()
            nl = ",".join(l1.split(" "))
            print "parse([%s],%s)." % (nl,l2[:-1])

