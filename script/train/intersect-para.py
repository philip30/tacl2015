#!/usr/bin/env python

import sys
import argparse
import gzip
import os
import os.path

parser = argparse.ArgumentParser()
parser.add_argument("--input", required=True, type=str)
parser.add_argument("--paraphrase", required=True, type=str)
parser.add_argument("--output", required=True, type=str)
args = parser.parse_args()

def make_line(line_str):
    ret = []
    for tok in line_str.split()[:-2]:
        if tok[0] == '"' and tok[-1] == '"':
            ret.append(tok)
        else:
            ret.append("NT")
    return " ".join(ret)

print >> sys.stderr, "Reading paraphrase translation model"
para_feat = {}
first = True
counter = 0
with gzip.open(args.paraphrase) as para_input:
    for line in para_input:
        line = line.strip().split(" ||| ") # source ||| target ||| feat
                
        para_feat[make_line(line[0]), make_line(line[1])] = " ".join(map(lambda x: "para-" + str(x), line[2].split()))
        if first:
#            print >> sys.stderr, "Example:", make_line(line[0]), make_line(line[1])
#            print >> sys.stderr, "        ", para_feat[make_line(line[0]),make_line(line[1])]
            first = False
        counter += 1
        if counter % 100000 == 0:
            print >> sys.stderr, counter

print >> sys.stderr, "Intersecting translation model"

def intersect(input_dir, output_dir):
    parent_input_dir = ("/".join(input_dir.split("/")[:-1]))
    parent_output_dir = ("/".join(output_dir.split("/")[:-1]))

    if os.path.isfile(output_dir):
        os.system("rm -rf %s" % (output_dir))

    os.system("mkdir -p %s" % (parent_output_dir))
    os.system("cp -r %s %s" % (input_dir, parent_output_dir))
    modify_ini(output_dir)

    hit, total = 0, 0
    with gzip.open(output_dir + "/model/rule-table.gz", "w") as file_out:
        with gzip.open(input_dir + "/model/rule-table.gz", "r") as file_in:
            for line in file_in:
                line = line.strip().split(" ||| ")
                source_str = make_line(line[0])
                target_str = make_line(line[1].split(" |COL| ")[0])
                total += 1
                if (source_str, target_str) in para_feat:
                    hit += 1
                    line[2] = line[2] + " " + para_feat[source_str,target_str]
                file_out.write(" ||| ".join(line) + "\n")

    print >> sys.stderr, "Coverage for %s: (%d/%d) = %.2f" % (input_dir, hit, total, float(hit)/total)

def modify_ini(dest_dir):
    with open(dest_dir + "/model/travatar.ini", "r") as inp:
        lines = inp.readlines()
    lines[1] = dest_dir + "/model/rule-table.gz\n"
    with open(dest_dir + "/model/travatar.ini" , "w") as out:
        for line in lines:
            out.write(line)

for run in range(1):
    for fold in range(10):
        intersect(args.input + "/run-%d/fold-%d/train" % (run, fold),\
                args.output + "/run-%d/fold-%d/train" % (run,fold))
        for fold_tune in range(10):
            intersect(args.input + "/run-%d/fold-%d/tune/train-%d" % (run,fold,fold_tune),
                    args.output + "/run-%d/fold-%d/tune/train-%d" % (run,fold,fold_tune))

