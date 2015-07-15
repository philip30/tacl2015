#!/usr/bin/python

import sys

skip_begin = len("parse([")
skip_end = len("],")

for line in sys.stdin:
    cols = line.strip().split()
    sent = cols[0][skip_begin : -skip_end].split(",")

    if sent[-1] == "'.'" or sent[-1] == "?":
        sent = sent[:-1]
    print >> sys.stderr, " ".join(sent)
    print " ".join(cols[1:])[:-2] + "."
