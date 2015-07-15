#!/usr/bin/python

import sys

for line in sys.stdin:
    line = line.strip()
    print "execute_funql_query(%s, Answer)." % (line[:-1])
