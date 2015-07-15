#!/usr/bin/python
# script to turn stdin into an n-best type
# 

import sys
import argparse

for i, line in enumerate(sys.stdin):
    line = line.strip()
    print "%d ||| %s ||| 1" % (i, line)


