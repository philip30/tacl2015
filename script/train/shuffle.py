#!/usr/bin/python

import sys
import argparse

parser = argparse.ArgumentParser(description="Shuffle")
parser.add_argument("--align", required=True)
parser.add_argument("--id", required=True)
args = parser.parse_args()

align = []
id=[]

with open(args.id) as idfp:
    for line in idfp:
        id.append(int(line.strip()))

with open(args.align) as alignfp:
    for line in alignfp:
        line_col = line.strip().split()
        inner_alignment = {}
        for elem in line_col:
            q,k = elem.split("-")
            inner_alignment[int(q)] = int(k)
        align.append(inner_alignment)

def print_rule(n, src_col, head, trg, s, span):
    result = "%s ||| %s ||| %s ||| %s" % (n, " ".join(src_col + ["@", head]), trg, span)
    h_result = hash(result)
    if h_result not in s:
        s.add(h_result)
        print result

def find_first_alignment(start_index, align_map):
    index = start_index
    limit = max(align_map.keys())
    while index not in align_map and index <= limit:
        index += 1
    if index > limit:
        raise Exception("Could not found start index: %s" % start_index)
    return index

#def rearrange_keyword(src, spans_ori, align_map):
#    if len(spans_ori) != len(src):
#        raise Exception("Uncorresponding span: %s to %s" % (str(src), str(spans_ori)))
#    spans = map(lambda x: x.split("-"), spans_ori)
#    spans = map(lambda x: find_first_alignment(int(x[0]),align_map), spans)
#    coupled = [(x,y) for (x,y) in zip(spans,src)]
#    coupled = map(lambda x: (align_map[x[0]], x[1]), coupled)
#    coupled = sorted(coupled, key=lambda x: x[0])
#    #checking for consistencies:
#    min_span, max_span = coupled[0][0], coupled[-1][0]  
#    
#    print >> sys.stderr, str(min_span), str(max_span)
#    print >> sys.stderr, spans_ori
#    print >> sys.stderr, align_map
#    covered = set()
#    for begin, end in map(lambda x:x.split("-"), spans_ori):
#        for i in range(int(begin),int(end)+1):
#            covered.add(i)
#    print >> sys.stderr, "Covered:", covered
#    not_covered = set()
#    for q, k in align_map.items():
#        if q not in covered:
#            not_covered.add(k)
#    print >> sys.stderr, "Not covered:", not_covered
#
#    not_valid = False
#    for k in not_covered:
#        if k > min_span and k < max_span:
#            not_valid = True
#
#    print >> sys.stderr, "Valid:", str(not not_valid)
#    print >> sys.stderr, "-----------------------------------------------------------"
#    return [x[1] for x in coupled] if not not_valid else None

def rearrange_keyword(src, spans_ori, align_map):
    print >> sys.stderr, "----->", str(src), "|||", str(spans_ori)
    print >> sys.stderr, str(align_map)
    if len(spans_ori) != len(src):
        raise Exception("Uncorresponding span: %s to %s" % (str(src), str(spans_ori)))
    spans = map(lambda x: x.split("-"), spans_ori)
    spans = map(lambda x: (int(x[0]), int(x[1])), spans)
    coupled = [(x,y) for (x,y) in zip(spans,src)]
    #coupled = map(lambda x: ((align_map[x[0][0]],align_map[x[0][1]]),x[1]),coupled)
    temp = []
    for (begin, end), src in coupled:
        cover_min, cover_max = len(src)+1, -1
        for i in range(begin, end+1):
            if i in align_map:
                cover_min = min(cover_min, align_map[i])
                cover_max = max(cover_max, align_map[i])
        if cover_max == -1:
            print >> sys.stderr, "Could not find cover for span " + str((begin, end)) 
            return None
        g = sorted([cover_min, cover_max])
        temp.append((tuple(g), src))
    coupled = sorted(temp, key=lambda x:x[0][0])
    return [x[1] for x in coupled]

for rule in sys.stdin:
    rule = rule.strip()
    n, src, trg, span = rule.split(" ||| ")

    s = set()
    src_col = src.split()
    src_str = src_col[:-2]
    src_str = rearrange_keyword(src_str, span.split(), align[id[int(n)]])
    
    if src_str is not None:
        print_rule(n, src_str, src_col[-1], trg, s, span)
    else:
        print >> sys.stderr, "Reject:", rule

