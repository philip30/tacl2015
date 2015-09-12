#!/usr/bin/python

import sys
import argparse
from collections import defaultdict

parser = argparse.ArgumentParser(description="Run nbest-eval-para")
parser.add_argument("--human-eval", nargs="+", type=str,required=True)
parser.add_argument("--answer", type=str, required=True)
parser.add_argument("--limit", type=int, default=1000)
parser.add_argument("--proposed", type=str, required=True)
args = parser.parse_args()

def all_equal(l):
    elem = None
    for x in l:
        if elem is None:
            elem = x
        elif elem != x:
            return False
    return True

# Read answer

answer = defaultdict(lambda:defaultdict(lambda:set()))
best_1 = {}
with open(args.answer) as answer_fp:
    for line in answer_fp:
        line = line.strip().split(" ||| ")
        if len(line) == 6:
            n, position, sys_str, para, correct, best1 = line
            n = int(n)
            correct = correct == "True"
            best1 = best1 == "True"
            answer[n][para].add((sys_str, correct, best1, position))
            if best1 and n not in best_1:
                best_1[n] = (para, correct)

# Read Human evaluation
number = 0
keyword = {}
Error = False
eval = defaultdict(lambda: set())
for human_id, human_fp_file in enumerate(args.human_eval):
    with open(human_fp_file) as human_fp:
        while True:
            line = human_fp.readline()
            if not line:
                break
            
            line = line.strip()
            if len(line) == 0:
                continue
            
            line = line.split(",")
            if (len(line[0]) != 0):
                number = int(line[0])
                keyword[number] = line[1]
                if number > args.limit:
                    break
            if len(line[-2]) == 0:
                print >> sys.stderr, "%d has an incomplete score!" % (number)
                Error = True
                continue
            
            line_data = ["", "-1", "Z"]
            line_data[0] = line[2].replace(";",",")
            line_data[1] = int(line[-2])
            if len(line[-1]) != 0:
                line_data[2] = line[-1]
            eval[number,human_id].add(tuple(line_data))

if Error:
    sys.exit(1)

# Perform evaluation
count = defaultdict(lambda:0)
systems = set()
rankings = set()
recall_divider = 0

# others
a_stat = {}

# Collect statistics
for (number,human_id), nbest in sorted(eval.items()):
    if len(nbest) == 0:
        raise Exception("Should not be 0!")
    
    for query, score, ranking in nbest:
        ref = answer[number][query]
        is_correct = False
        for sys, correct, best, position in ref:
            count["%s_%s_%s" % (sys,ranking, "true" if correct else "false")] += 1
            count[sys+"_"+ranking] += 1
            count[sys] += 1
            systems.add(sys)
            
            if correct:
                is_correct = True
            if best:
                if correct:
                    answer[n][para].add((sys_str, correct, best1, position))
                count["%s_%d_%s" % (sys,score, "true" if correct else "false")] += 1
                count[sys+"_"+str(score)] += 1
                count["%s_best" % sys] += 1

        if ranking != "Z":
            count[ranking] += 1
            count["total_"+ranking] += 1
            rankings.add(ranking)

            if is_correct:
                count["%s_correct" % ranking] += 1
        if ranking == "A":
            a_stat[number] = (query, score, is_correct)

agreement = defaultdict(lambda:[])
for (number, human_id), nbest in sorted(eval.items()):
    agreement[number].append(list(nbest))

# COUNT AGREEMENT
agreement_divider = 0
letter_divider = 0
score_agree = 0
letter_agree = 0
for number, nbests in agreement.items():
    if len(nbests) > 1:
        for i in range(len(nbests[0])):
            items = [(x[1], x[2]) for x in [y[i] for y in nbests]]
            score_agree += 1 if all_equal([x[0] for x in items]) else 0
            
            letters = [x[1] for x in items]
            if any([x != 'Z' for x in letters]):
                letter_divider += 1
                letter_agree += 1 if all_equal(letters) else 0
            
            agreement_divider += 1

print "STATISTIC COUNT:"
for a,b in sorted(count.items()):
    print a,b

print "=========================="
print "SYSTEM ACCURACY:"
for sys in systems:
    print "[System: %s]" % sys
    for score in [0,1,2]:
        print "Score %d = %f" % (score, float(count[sys+"_"+str(score)]) / count[sys + "_best"])
        for judge in ["true","false"]:
            print "%s_%d_%s" % (sys,score,judge),":", "%2.2f" % (float(count["%s_%d_%s" %(sys,score,judge)])/count[sys+"_"+str(score)] * 100), '%'
    print "[Ranking Score]"
    for ranking in ["A", "B", "C", "D"]:
        for judge in ["true", "false"]:
            print "%s_%s_%s" % (sys,ranking,judge),":", "%2.2f" % (float(count["%s_%s_%s" % (sys,ranking,judge)])/count[sys+"_"+ranking] * 100), '%'
    print "------------------"    
print "ONE BEST ACCURACY/RECALL:"
for sys in systems:
    print sys, ":", "%2.2f" % (float(count["%s_best_correct" % sys]) / count[sys+"_best"] * 100) + ' %'

print "==========================="
print "HUMAN ACCURACY:"
for ranking in sorted(rankings):
    print "%s : %2.2f" % (ranking, float(count[ranking+"_correct"]) / count[ranking] * 100) + '%'

print "==========================="
print "GET WORSE OR BETTER"
worse = 0
better = 0
proposed_correct = count["%s_best_correct" % (args.proposed)]
for number, (query, score, correct) in sorted(a_stat.items()):
    kw = keyword[number]
    b1_para, b1_correct = best_1[number]
    

#    print number, query, score, correct, b1_correct
    if b1_correct != correct:
        print "ID:", number
        print "Keyword:", kw
        print "best 1 paraphrase:", b1_para
        print "Human choice:", query
        print "Human Score:", score
        print "WORSE" if b1_correct else "BETTER"
        print 
        
        if b1_correct:
            worse += 1
            proposed_correct -= 1
        else:
            better += 1
            proposed_correct += 1

print "Better/Worse = %d/%d" %(better, worse)

print "============================"
print "Accuracy +human"
print "%s: %2.2f" % ("+Human", (float(proposed_correct) / count[args.proposed + "_best"] * 100)) + '%'


print "HUMAN RECALL:"
for ranking in sorted(rankings):
    print "%s : %2.2f" % (ranking, float(count[ranking+"_correct"]) / len(eval) * 100 ) + '%'
print "Total:", len(eval)

print "-----------------------------------"
print "HUMAN AGREEMENT:"
if agreement_divider != 0:
    print "Score Agreement: %f" % (float(score_agree) / agreement_divider * 100) +'%'
if letter_divider != 0:
    print "Letter Agreement: %f" % (float(letter_agree) / letter_divider * 100) +'%'
print "Agreement_divider:", agreement_divider
