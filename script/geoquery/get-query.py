#!/usr/bin/python

import sys


for line in sys.stdin:
    print line.strip().split("\t")[1].split(" |COL| ")[0] + ".\n\n\n\n\n\n"
