#!/usr/bin/python

import sys
import argparse
import random
from collections import defaultdict

ITERATIONS = int(1e5)

BAD_QUERY = "Answer = [BadQuery]"
EMPTY_RESULT = "Answer = [EmptyResult]"
TIMEOUT_RESULT = "Answer = [Timeout]"
ERROR = set([BAD_QUERY,EMPTY_RESULT,TIMEOUT_RESULT])

parser = argparse.ArgumentParser(description="Argument Parser")
parser.add_argument("--baseline", type=str, required=True, nargs="+")
parser.add_argument("--input", type=str, required=True, nargs="+")
parser.add_argument("--gs", type=str, required=True, nargs="+")
args = parser.parse_args()

total_test = 0
for gs_file_str in args.gs:
    with open(gs_file_str) as gs_file:
        for line in gs_file:
            total_test += 1

def load_file(stat_files):
    ret = []
    # 1 best list
    n_set = set()

    # Counting parseble, total and correct
    for (token, input_file) in enumerate(stat_files):
        # For every stat.res
        with open(input_file) as i_file:
            # Read every line inside it
            for line in i_file:
                s_id, answer, stat = line.strip().split("\t")
                res, _ = stat.split()
    
                if (token, s_id) not in n_set:
                    n_set.add((token, s_id))
    
                    is_parseable = False
                    is_correct = False

                    # Not error OK we can parse this sentence
                    if answer not in ERROR:
                        is_parseable = True
                
                    # The answer is correct
                    if res == "1":
                        is_correct = True
                    ret.append((is_correct, is_parseable))

    # handle empty n-best list
    while len(ret) < total_test:
        ret.append((False, False))

    return ret

def calc_stats(stat):
    total_correct = 0
    total_parseable = 0
    for correct, parseable in stat:
        if correct: 
            total_correct += 1
        if parseable:
            total_parseable += 1
    acc = float(total_correct) / total_parseable
    rec = float(total_correct) / len(stat)
    f1 = 2 * acc * rec / (acc + rec)
    return acc, rec, f1

data_1 = load_file(args.baseline)
data_2 = load_file(args.input)

# Bootstrap_resampling
diffs = [[0,0,0],[0,0,0],[0,0,0]]
order = list(range(len(data_1)))
cnt = int(len(order)/2)
for i in range(ITERATIONS):
    random.shuffle(order)
    half_1 = calc_stats([data_1[x] for x in order[0:cnt]])
    half_2 = calc_stats([data_2[x] for x in order[0:cnt]])
    for x in range(3):
        if half_1[x] > half_2[x]:
            diffs[x][0] += 1.0/ITERATIONS
        elif half_1[x] < half_2[x]:
            diffs[x][2] += 1.0/ITERATIONS
        else:
            diffs[x][1] += 1.0/ITERATIONS

names = ["Accuracy", "Recall", "F-measure"]
for i in range(3):
    if diffs[i][0] > 0.95:
        print("%s: Baseline > System (%f)" % (names[i], diffs[i][0]))
    elif diffs[i][2] > 0.95:
        print("%s: Baseline < System (%f)" % (names[i], diffs[i][2]))
    else:
        print("%s: No Difference (%r)" % (names[i], diffs[i]))

    
    
