#!/usr/bin/python

import sys

for line in sys.stdin:
    line = line.strip().split(" ||| ")
    paraphrase = line[1].split(" |COL| ")[0]
    print paraphrase
