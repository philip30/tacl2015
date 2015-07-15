#!/usr/bin/python
# Script to make 3 sync grammar
# Usage: 3-sync.py [KEYWORD] [QUESTION]


import sys
import gzip
from collections import defaultdict

INDEX = 0
SRC = 1
TRG = 2
MAP = 3
HEAD = 4

def parse_rule(rule_str):
    rule_col = rule_str.split(" ||| ")
    index, src, mrl = rule_col[0], rule_col[1], rule_col[2]
    rule_map = defaultdict(lambda:[])
    src_result, trg_result = ([], [])
    src_rule, src_head = src.split(" @ ")
    trg_rule, trg_head = mrl.split(" @ ")
    for i, token in enumerate(src_rule.split(" ")):
        if token[0] == '"' and token[-1] == '"':
            src_result.append(token)
        elif token == '@': 
            break
        else:
            var, label = token.split(":")
            src_result.append(label)
            rule_map[var].append(i)
    for i, token in enumerate(trg_rule.split(" ")):
        if token[0] == '"' and token[-1] == '"':
            trg_result.append(token)
        elif token == '@':
            break
        else:
            var, label = token.split(":")
            trg_result.append(label)
            rule_map[var].append(i)

    ret_map = {}
    for (var, l) in rule_map.items():
        ret_map[l[0]] = l[1]
    
    return (index, src_result, trg_result, ret_map, src_head)

def process(k_fp, q_fp):
    keyword_rules = defaultdict(lambda:[])
    for k_line in k_fp:
        k_line = k_line.strip()
        k_rule = parse_rule(k_line)
        keyword_rules[k_rule[INDEX]].append(k_rule)
    
    for q_line in q_fp:
        q_rule = parse_rule(q_line.strip())
        for k_rule in keyword_rules[q_rule[INDEX]]:
            if k_rule[TRG] == q_rule[TRG] and k_rule[HEAD] == q_rule[HEAD]:
                print q_rule[INDEX], "|||", merge_rule(k_rule, q_rule)

def merge_rule(k_rule, q_rule):
    kword = []
    question = []
    mrl = []
    temp_map = {}
    for i, word in enumerate(k_rule[SRC]):
        if word[0] == '"' and word[-1] == '"':
            kword.append(word)
        else:
            new_var = "x%d" % (len(temp_map))
            temp_map[k_rule[MAP][i]] = new_var
            kword.append("%s:%s" % (new_var, word))
    kword.append("@ %s" % (k_rule[HEAD]))

    for i, word in enumerate(k_rule[TRG]):
        if word[0] == '"' and word[-1] == '"':
            mrl.append(word)
        else:
            mrl.append("%s:%s" % (temp_map[i],word))
    mrl.append("@ %s" % (k_rule[HEAD]))

    for i, word in enumerate(q_rule[SRC]):
        if word[0] == '"' and word[-1] == '"':
            question.append(word)
        else:
            question.append("%s:%s" % (temp_map[q_rule[MAP][i]], word))
    question.append("@ %s" % (q_rule[HEAD]))
    
    return "%s ||| %s |COL| %s" % (" ".join(kword), " ".join(question), " ".join(mrl))
            


with (gzip.open(sys.argv[1]) if sys.argv[1].endswith(".gz") else open(sys.argv[1])) as k_fp:
    with (gzip.open(sys.argv[2]) if sys.argv[2].endswith(".gz") else open(sys.argv[2])) as q_fp:
        process(k_fp, q_fp)
