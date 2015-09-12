#!/usr/bin/python

import sys
import argparse
import itertools
from collections import defaultdict

parser = argparse.ArgumentParser(description="3 Sync Grammar")
parser.add_argument('--stopword', type=str, required=True)
args = parser.parse_args()

stopwords = set()
with open(args.stopword) as swfp:
    for line in swfp:
        if not line.startswith("#"):
            stopwords.add(line.strip())

def print_rule(n, src_col, head, src, trg, span):
    result = "%s ||| %s ||| %s ||| %s" % (n, " ".join(src_col + ["@", head]), " |COL| ".join([src, trg]),span)
    print result

def extract_symbol(head):
    return head[:head.index("[")] if "[" in head else head

for rule in sys.stdin:
    rule = rule.strip().split(" ||| ")
    n, src, trg, span = rule[0], rule[1], rule[2], rule[3]

    src_col = src.split(" ")
    span_col = span.split(" ")
    head = src_col[-1]
    new_src, new_span = [], []
    for src_elem, span_elem in zip(src_col[:-2], span_col):
        if src_elem[1:-1] not in stopwords:
            new_src.append(src_elem)
            new_span.append(span_elem)
    
    if len(new_src) == 0:
        continue

    # To prevent Loop from FORM -> CONJ
    if len(new_src) == 1:
        if new_src[0][0] != '"' and new_src[0][-1] != '"':
            head_src = new_src[0].split(":")[-1]
            if head_src.startswith("CONJ") and head.startswith("FORM"):
                continue
            if extract_symbol(head_src) == extract_symbol(head):
                continue
    
    print_rule(n, new_src, head, src, trg, " ".join(new_span))

