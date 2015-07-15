#!/usr/bin/python

import sys

function = sys.argv[1]

for line in sys.stdin:
    line = line.strip()
    print "%s(%s, Answer)." % (function, line[:-1])
