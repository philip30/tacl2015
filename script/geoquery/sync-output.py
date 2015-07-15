#!/usr/bin/env python

import sys
import argparse

parser = argparse.ArgumentParser(description="Synchronize Output")
parser.add_argument("--sync", type=str, required=True)
parser.add_argument("--inp", type=str,required=True)
parser.add_argument("--n", type=str, required=True)
args = parser.parse_args()

ERROR = "Answer = [BadQuery]"

sync_file= []
with open(args.sync) as sync_fp:
    for line in sync_fp:
        sync_file.append(line.strip())

inp_file = []
with open(args.inp) as inp_fp:
    for line in inp_fp:
        inp_file.append(line.strip())

n_file = []
with open(args.n) as n_fp:
    for line in n_fp:
        n_file.append(line.strip().split("\t")[0])

inp_file = filter(lambda x: len(x.strip()) != 0, inp_file[2:])
sync_file = filter(lambda x: len(x.strip()) != 0, sync_file[22:-2])

sync_ptr = 0
inp_ptr = 0
n = 0
while sync_ptr < len(sync_file) and sync_file[sync_ptr] != "":
    #print >> sys.stderr, sync_file[sync_ptr], (sync_ptr + 1)
    if sync_file[sync_ptr] == "true.":
        print n_file[n] + "\t" + inp_file[inp_ptr]
        sync_ptr += 1
        inp_ptr += 1
    elif sync_file[sync_ptr].strip().startswith("ERROR"):
        if "Type error" in sync_file[sync_ptr]:
            sync_ptr += 2
        elif "Syntax error" in sync_file[sync_ptr]:
            sync_ptr += 4
        elif "toplevel" in sync_file[sync_ptr]:
            sync_ptr += 1
        elif "global stack" in sync_file[sync_ptr]:
            sync_ptr += 2
        else:
            raise Exception("Unhandled:", sync_file[sync_ptr])
        print n_file[n] + "\t" + ERROR
    elif sync_file[sync_ptr].strip().startswith("^  Exception:"):
        sync_ptr += 1
        print n_file[n] + "\t" + ERROR
    elif sync_file[sync_ptr].strip().startswith("% ... 1"):
        sync_ptr += 3
        print n_file[n] + "\t" + ERROR
    elif sync_file[sync_ptr] == "":
        break
    else:
        raise Exception("Unhandled:", sync_file[sync_ptr])
    n += 1

