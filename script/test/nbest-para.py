#!/usr/bin/python

import sys
import argparse
import random
from collections import defaultdict

argparse = argparse.ArgumentParser(description="Human Para")
argparse.add_argument('--unstemmed_question', type=str, required=True)
argparse.add_argument('--keyword', type=str, required=True)
argparse.add_argument('--input', nargs='+', type=str, required=True, default=[])
argparse.add_argument('--top', type=int,default=300)
argparse.add_argument('--nbest', type=int, default=5)
argparse.add_argument('--stem', type=str)
argparse.add_argument('--test_dir', nargs='+', type=str)
args = argparse.parse_args()

if args.test_dir == None:
    args.test_dir = ["test"] * len(args.input)

SENT_MAP = 2

test_set = {}
for i in range(10): # For each Fold 
    question_f = open("%s/run-0/fold-%i/test.sent" % (args.unstemmed_question, i))
    keyword_f = open("%s/run-0/fold-%i/test.sent" % (args.keyword, i))
    for j, (q, k) in enumerate(zip(question_f, keyword_f)):
        q, k = (q.strip(), k.strip())
        test_set[i,j] = [q,k,defaultdict(lambda:[])]

for i in range(10):
    for f, t in zip(args.input,args.test_dir):
        with open(f + "/run-0/fold-%i/%s/nbest.stats.red" % (i,t)) as of:
            for line in of:
                line = line.strip()
                n, line, result = line.split("\t")
                if line == "Error":
                    continue
                line = line.split(" |COL| ")[1]
                result = result == "1 1"
                test_set[i,int(n)][SENT_MAP][f].append([line, result, False])

stem_map = None
if args.stem:
    stem_map = {}
    with open(args.stem) as stem_f:
        for line in stem_f:
            stem, expansion = line.split("\t")
            stem_map[stem] = []
            for word in expansion.split():
                stem_map[stem].append(word)

keys = [k for k in test_set.keys()]
random.shuffle(keys)

def map_stem(q, stem_map, orig):
    if not stem_map:
        return q

    orig = set(orig.split())
    result = []
    for tok in q.split():
        to_be_filtered = []
        if tok in stem_map:
            to_be_filtered = stem_map[tok]
        eligible = filter(lambda x: x in orig, to_be_filtered)
        if len(eligible) == 0:
            if len(stem_map[tok]) != 0:
                eligible = stem_map[tok]
            else:
                eligible = [tok]

        if len(eligible) > 1:
            result.append("{%s}" % (",".join(eligible)))
        else:
            result.append(eligible[0])
    return " ".join(result)

count = 0
for key in keys:
    (q, k, outputs) = test_set[key]
    check = True
    if len(outputs) != len(args.input):
        continue
    
    if count >= args.top:
        break

    p = []
    for f, list_out in outputs.items():
        percentage = float(len(filter(lambda x: x[1], list_out))) / len(list_out)
        p.append((f,percentage))

    remap = defaultdict(lambda:[]) 
    uniq = set()
    for f, list_out in outputs.items():
        item = list_out.pop(0)
        remap[f].append(item)
        uniq.add(item[0])
        item[2] = True # Best 1
        n_count = 0
        for item, result, n_best in list_out:
            if n_count >= args.nbest:
                break
            if item[0] not in uniq and len(item.strip()) != 0:
                item = item,result,n_best
                remap[f].append(item)
                uniq.add(item[0])
                n_count += 1
   
    if len(uniq) <= 1:
        continue

    print "%d). %s" % ((count+1), map_stem(k,stem_map,q))
    print >> sys.stderr, "%d ||| Question ||| %s ||| %s" % (count+1, q, " ".join([str(x) + ":" + str(y) for x,y in p]))
    
    uniq_list = list(uniq)
    random.shuffle(uniq_list)
    for item in list(uniq_list):
        print map_stem(item,stem_map,q)

    for k, item in remap.items():
        random.shuffle(item)
        for l in item:
            print >> sys.stderr, "%d ||| %s ||| %s ||| %s ||| %s ||| %s" % (count+1, str(key), k, map_stem(str(l[0]),stem_map,q),str(l[1]),str(l[2]))

    print ""
    count += 1
    
