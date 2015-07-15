#!/usr/bin/python

import sys
import argparse
import random
from collections import defaultdict

parser = argparse.ArgumentParser(description="Human Test Maker")
parser.add_argument("--input", required=True, type=str)
parser.add_argument("--person", type=int, default=3)
parser.add_argument("--workload", type=int, default=300)
parser.add_argument("--output", type=str, required=True)
args = parser.parse_args()

def read_test_file(inp):
    ret = []
    i = 0
    while i < len(inp):
        line = inp[i].strip()
        if len(line) == 0: continue
        if ")." in line:
            number, keyword = line.split(").")
            number = int(number.strip())
            keyword = keyword.strip()
            nbest = []
            j = i+1
            while j < len(inp) and len(inp[j].strip()) > 0:
                nbest.append(inp[j].strip())
                j += 1
            ret.append({"keyword": keyword, "nbest": nbest, "number":number})
            i = j
        else:
            raise Exception("Bad line:", line)
        i += 1
    return ret

def generate_random_list(size, inp):
    ret = set()
    while size > 0:
        random_index = random.randint(0,len(inp)-1)
        if random_index not in ret:
            ret.add(random_index)
            size -= 1
    return [inp[i] for i in ret]

def generate_distributed_list(inp, rand, person):
    ret = []
    rand_set = set()
    for i in range(person):
        ret.append([])
    i = 0
    while len(rand) > 0:
        next = rand.pop()
        ret[i].append(next)
        ret[(i+1)%person].append(next)
        rand_set.add(next["number"])
        i = (i+1) % person
    while len(inp) > 0:
        next = inp.pop()
        if (next["number"] not in rand_set):
            ret[i].append(next)
            i = (i+1) % person
    return ret

inp = []
with open(args.input) as input_file:
    for line in input_file:
        inp.append(line.strip())

test_file = read_test_file(inp)
total_size = args.workload * args.person
intersection_size = total_size - len(test_file)
random_list = generate_random_list(intersection_size, test_file)
distributed_list = generate_distributed_list(test_file, random_list, args.person)

for i, l in enumerate(distributed_list):
    with open(args.output+"/eval-" + str(i+1) + ".csv", "w") as output:
        for elem in sorted(l[:args.workload], key=lambda l: l["number"]):
            nbest = elem["nbest"]
            keyword = elem["keyword"].strip()
            number = elem["number"] + 1
            print >> output, "%d,%s,%s" % (number,keyword.replace(",",";"),nbest[0].strip().replace(",",";"))
            for line in nbest[1:]:
                print >> output, ",,%s" % (line.strip().replace(",",";"))
            print >> output, ""

