#!/usr/bin/env perl

use strict;
use utf8;
use Getopt::Long;
use List::Util qw(sum min max shuffle);
binmode STDIN, ":utf8";
binmode STDOUT, ":utf8";
binmode STDERR, ":utf8";

my ($INPUT,$WORKING_DIR,$TRAVATAR,$STANFORD_JAR,$SRILM,$STEM);

my ($PREFIX, $TUNING);
my $N_GRAM = "4";

GetOptions(
# Required
    "input=s" => \$INPUT, 
    "working-dir=s" => \$WORKING_DIR,
    "travatar=s" => \$TRAVATAR,
    "stanford-parser=s" => \$STANFORD_JAR,
    "srilm=s" => \$SRILM,
# Optional
    "tuning=s" => \$TUNING,
    "n-gram=s" => \$N_GRAM,
    "prefix=s" => \$PREFIX,
    "stem!" => \$STEM,
);

if (not (defined ($INPUT) && defined($WORKING_DIR) && defined($TRAVATAR) 
        && defined ($STANFORD_JAR) && defined($SRILM))) 
{
    die "Usage make-lm.pl -input [INPUT] -working-dir [WORKING DIR] -travatar [TRAVATAR] -stanford-parser [STANFORD] -srilm [SRILM]"; 
}

if (-d $WORKING_DIR) {
    safesystem("rm -rf $WORKING_DIR") or die;
}
safesystem("mkdir -p $WORKING_DIR") or die;

my $file_name = ($PREFIX ? $PREFIX : substr($INPUT, rindex($INPUT, '/')+1));
safesystem("java -cp $STANFORD_JAR edu.stanford.nlp.process.PTBTokenizer -preserveLines $INPUT | sed 's/(/-LRB-/g; s/)/-RRB-/g' | sort -u > $WORKING_DIR/$file_name.tok") or die;
safesystem("$TRAVATAR/script/tree/lowercase.pl < $WORKING_DIR/$file_name.tok > $WORKING_DIR/$file_name.toklow") or die;

if ($STEM) {
    safesystem("script/data/stem.pl < $WORKING_DIR/$file_name.toklow > $WORKING_DIR/$file_name.stem") or die;
    safesystem("sed -i \"s/which/what/g\" $WORKING_DIR/$file_name.stem") or die;
    safesystem("mv $WORKING_DIR/$file_name.stem $WORKING_DIR/$file_name.toklow") or die;
}

safesystem("$TRAVATAR/src/kenlm/lm/lmplz -o $N_GRAM < $WORKING_DIR/$file_name.toklow > $WORKING_DIR/$file_name.arpa") or die;
safesystem("$SRILM/ngram -lm $WORKING_DIR/$file_name.arpa -renorm -write-lm $WORKING_DIR/$file_name.renorm") or die;

# If we interpolate it with something
my $arpa = "$file_name.renorm";

safesystem("$TRAVATAR/src/kenlm/lm/build_binary -i $WORKING_DIR/$arpa $WORKING_DIR/$file_name.blm") or die;

# /Auxiliary functions
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

