#!/usr/bin/python
# Script to calculate score of Accuracy, Recall, and F-Score
# usage calculate-score.py -i [INPUT FILE...]
# Philip Arthur (philip.arthur30@gmail.com)

import sys
import argparse
from collections import defaultdict

# Type of Error
BAD_QUERY = "Answer = [BadQuery]"
EMPTY_RESULT = "Answer = [EmptyResult]"
TIMEOUT_RESULT = "Answer = [Timeout]"
ERROR = set([BAD_QUERY,EMPTY_RESULT,TIMEOUT_RESULT])

# Arguments
parser= argparse.ArgumentParser(description="Calculate Score")
parser.add_argument('-i', nargs='+', type=str, dest='input', default=[], required=True)
parser.add_argument('-gs', nargs='+', type=str, required=True) 

args = parser.parse_args()

total = 0
for gs_file_str in args.gs:
    with open(gs_file_str) as gs_file:
        for line in gs_file:
            total += 1

# 1 best list
n_set = set()
oracle_m = defaultdict(lambda:0)

# Counting parseble, total and correct
parseable = 0
correct = 0
for (token, input_file) in enumerate(args.input):
    # For every stat.res
    with open(input_file) as i_file:
        # Read every line inside it
        for line in i_file:
            s_id, answer, stat = line.strip().split("\t")
            res, _ = stat.split()

            if (token, s_id) not in n_set:
                n_set.add((token, s_id))

                # Not error OK we can parse this sentence
                if answer not in ERROR:
                    parseable += 1
            
                # The answer is correct
                if res == "1":
                    correct += 1
            if res == "1":
                oracle_m[(token,s_id)] += 1

print correct, parseable, total

# Counting the numbers
acc = float(100 * correct) / parseable if parseable > 0 else 0
rec = float(100 * correct) / total if total > 0 else 0
f1 = 2 * acc * rec / (acc + rec)
oracle = float(100* len(oracle_m)) / total if total > 0 else 0

# Printing the numbers
print "Accuracy  : %2.2f" % (acc)
print "Recall    : %2.2f" % (rec)
print "F-Measure : %2.2f" % (f1)
print "Oracle    : %2.2f" % (oracle)
