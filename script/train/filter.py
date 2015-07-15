#!/usr/bin/python
# Script to filter the rule table according to hiero rule filtering
# Usage filter.py -i [INPUT] 
# Philip Arthur (philip.arthur30@gmail.com)

import sys
import argparse

parser = argparse.ArgumentParser(description="Filter Rule Table")
parser.add_argument('-i', required=True, dest="input", type=str)
args = parser.parse_args()

def is_nt(token):
    return len(token) != 0 and token[0] != '"' and token[-1] != '"'

def filter_pass(src):
    tokens = src.split()
    for i in range(1,len(tokens)):
        if tokens[i] == '@': 
            break
        if is_nt(tokens[i]) and is_nt(tokens[i-1]):
            return False
    return True

# Read all the rules
rules = []
with open(args.input) as rule_fp:
    for line in rule_fp:
        rule = line.strip()
        rules.append(rule)

# Print the rules if the rule pass the filter
with open(args.input,'w') as rule_fp:
    for rule in rules:
        src, trgs, feat = rule.split(" ||| ")
        if filter_pass(src):
            print >> rule_fp, rule

