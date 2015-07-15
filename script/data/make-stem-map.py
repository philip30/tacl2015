#!/usr/bin/python

import sys
from collections import defaultdict

stem_map = defaultdict(lambda:set())
with open(sys.argv[1]) as question: # unstemmed
    with open(sys.argv[2]) as stemmed: #stemmed
        for q_line, s_line in zip(question, stemmed):
            q_line = q_line.strip().split()
            s_line = s_line.strip().split()

            if len(q_line) != len(s_line):
                raise Exception ("%s != %s" % (" ".join(q_line), " ".join(s_line)))
            
            for q_token, s_token in zip(q_line, s_line):
                stem_map[s_token].add(q_token)

for stem, expansion_list in stem_map.items():
    print "%s\t%s" % (stem, " ".join(expansion_list))

