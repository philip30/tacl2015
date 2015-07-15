#!/usr/bin/python
# Script to retrive specific lines in file
# Usage: retrieve-lines.py [INPUT] [NUMBERS]
# Philip Arthur (philip.arthur30@gmail.com)

import sys

numbers = []

# Reading all the numbers
with open(sys.argv[2]) as num_file:
    for num in num_file:
        num = num.strip()
        numbers.append(int(num))

# Input File Reading
inp = []
with open(sys.argv[1]) as inp_file:
    for i, line in enumerate(inp_file):
        inp.append(line.strip())

for num in numbers:
    print inp[num]
