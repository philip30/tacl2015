#!/usr/bin/env perl

use strict;
use utf8;
use Getopt::Long;
use List::Util qw(sum min max shuffle);
binmode STDIN, ":utf8";
binmode STDOUT, ":utf8";
binmode STDERR, ":utf8";

my ($FORCE,$LM_FILE,$VERBOSE,$ONE_FEAT,$ALIGN,$DEL_FILE,$FILTER,$ADDITIONAL_RULE,$THREADS);

my $THREE_SYNC;
my $KB;
my $WORKING_DIR;
my $INPUT;
my $LETRAC;
my $PIALIGN;
my $STEM;
my $ID;
my $MANUAL_ALIGN;
my $SHUFFLE;
my $MAX_SIZE = "4";
my $TRG_FACTORS = "1";
my $THREADS = "24";

GetOptions(
# Required
    "working-dir=s" => \$WORKING_DIR,
    "kb=s" => \$KB,
    "input=s" => \$INPUT,
    "manual-align=s" => \$MANUAL_ALIGN,
    "pialign=s" => \$PIALIGN,
    "letrac=s" => \$LETRAC,
    "del-file=s" => \$DEL_FILE,
# Optional
    "id=s" => \$ID,
    "three-sync=s" => \$THREE_SYNC,
    "additional-rule=s" => \$ADDITIONAL_RULE,
    "force!" => \$FORCE,
    "lm-file=s" => \$LM_FILE,
    "verbose!" => \$VERBOSE,
    "one-feat!" => \$ONE_FEAT,
    "max-size=s" => \$MAX_SIZE,
    "align=s" => \$ALIGN,
    "trg-factors=s" => \$TRG_FACTORS,
    "filter!" => \$FILTER,
    "stem!" => \$STEM,
    "shuffle=s" => \$SHUFFLE,
    "threads=s" => \$THREADS,
);

if (not (defined ($KB) && defined($WORKING_DIR) && defined($INPUT) && defined($LETRAC) 
        && defined ($MANUAL_ALIGN) && defined($PIALIGN) && defined($DEL_FILE))) 
{
    die "Usage run-training.pl -kb [KB] -pialign [PIALIGN] -letrac [LETRAC] -input [INPUT] -working-dir [WORKING_DIR] -manual-align [MANUAL_ALIGN] -del-file [DEL_FILE]"; 
}

if (-d $WORKING_DIR) {
    if ($FORCE) {
        safesystem("rm -rf $WORKING_DIR");
    } else {
        die "Working dir exists: $WORKING_DIR";
    }
}

my $force = ($FORCE ? "-force" : "");
my $verbose = ($VERBOSE ? "-verbose" : "");
my $align = ($ALIGN ? "-align $ALIGN" :"");
my $del_file = ($DEL_FILE ? "--del_file $DEL_FILE" : "");
my $lm_file = ($LM_FILE ? "--lm_file ".$LM_FILE : "");
my $three_sync = ($THREE_SYNC ? "-three-sync $THREE_SYNC" : "");

print STDERR "===== EXECUTING TRAINING =====\n";
# Extraction
safesystem("$LETRAC/run-extraction.pl -threads $THREADS -manual $MANUAL_ALIGN -max-size $MAX_SIZE -merge-unary -letrac $LETRAC -input-file $INPUT -pialign $PIALIGN -working-dir $WORKING_DIR $align $verbose $force $three_sync") or die;
exit(0) if $VERBOSE;

if ($THREE_SYNC) {
    safesystem("script/train/make-3sync.py --stopword $THREE_SYNC < $WORKING_DIR/model/lexical-grammar.txt > $WORKING_DIR/model/3sync.txt") or die;
    safesystem("mv $WORKING_DIR/model/3sync.txt $WORKING_DIR/model/lexical-grammar.txt") or die;
} 

if ($SHUFFLE) {
    die "Should also specify -id" if not $ID;
    safesystem("script/train/shuffle.py --align $SHUFFLE --id $ID < $WORKING_DIR/model/lexical-grammar.txt > $WORKING_DIR/model/shuf.txt 2> $WORKING_DIR/model/shuffled.log") or die;
    safesystem("mv $WORKING_DIR/model/shuf.txt $WORKING_DIR/model/lexical-grammar.txt") or die;
}

my $one_feat = $ONE_FEAT ? "--one_feat" : "";
my $paralength = $LM_FILE ? "--paralength" : "";
safesystem("$LETRAC/script/train/feature.py --trg_factors $TRG_FACTORS $one_feat $paralength < $WORKING_DIR/model/lexical-grammar.txt > $WORKING_DIR/model/rule-table") or die;
my $grammar_num = (split ' ',`wc -l $WORKING_DIR/model/rule-table`)[0];
my $stem = $STEM ? "--stem script/data/stem.pl" : "";
safesystem("$LETRAC/script/train/append-rules.py -duplicate_src -i $KB --trg_factors $TRG_FACTORS < $WORKING_DIR/model/rule-table > $WORKING_DIR/model/rule+kb.txt") or die;
safesystem("$LETRAC/script/train/append-rules.py -i $DEL_FILE --trg_factors $TRG_FACTORS < $WORKING_DIR/model/rule+kb.txt > $WORKING_DIR/model/rule+kb+del.txt") or die;
safesystem("$LETRAC/script/train/append-rules.py -duplicate_src -i $ADDITIONAL_RULE --trg_factors $TRG_FACTORS < $WORKING_DIR/model/rule+kb+del.txt > $WORKING_DIR/model/rule-table") or die;
    
# Delete all unary rules
#safesystem("sed -i '/^x0:[^ ]* @/d' $WORKING_DIR/model/rule-table"); 

# This filtering is to filter the rule that has 2 adjacent non terminal. it doesn't help so much.
# All the accuracies drop. consider not using it then.
if ($FILTER) {
    safesystem("script/train/filter.py -i $WORKING_DIR/model/rule-table");
}

my $one_feat = $ONE_FEAT ? "--one_feat $grammar_num" : "";
safesystem("gzip $WORKING_DIR/model/rule-table") or die;
safesystem("$LETRAC/script/train/make-travatar-ini.py --trg_factors $TRG_FACTORS --tm_file $WORKING_DIR/model/rule-table.gz $lm_file $one_feat > $WORKING_DIR/model/travatar.ini") or die;

# Auxiliary functions
sub safesystem {
	print STDERR "Executing: @_\n";
	system(@_);
	if ($? == -1) {
		warn "Failed to execute: @_\n  $!";
		exit(1);
	} elsif ($? & 127) {
		printf STDERR "Execution of: @_\n  died with signal %d, %s coredump\n",
			   ($? & 127),  ($? & 128) ? 'with' : 'without';
		exit(1);
	} else {
		my $exitcode = $? >> 8;
		warn "Exit code: $exitcode\n" if $exitcode;
		return ! $exitcode;
	}
}

