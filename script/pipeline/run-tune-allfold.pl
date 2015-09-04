#!/usr/bin/env perl

use strict;
use utf8;
use Getopt::Long;
use List::Util qw(sum min max shuffle);
binmode STDIN, ":utf8";
binmode STDOUT, ":utf8";
binmode STDERR, ":utf8";

# Required
my ($WORKING_DIR, $TRAVATAR, $GEOQUERY, $LETRAC, $CONFIG, $TRG_FACTORS, $DATABASE, $FORCE, $DRIVER_FUNCTION, $LAMTRAM); 
my $FOLD_CONFIG;

# Optional
my $N_BEST="500";
my $THREADS="1";
my $ONE_FEAT;
my $NO_TYPECHECK;
my $CHECK_EMPTY;
my $NNLM;

GetOptions(
    "working-dir=s" => \$WORKING_DIR,
    "travatar=s" => \$TRAVATAR,
    "geoquery=s" => \$GEOQUERY,
    "lamtram=s" => \$LAMTRAM,
    "letrac=s" => \$LETRAC,
    "travatar-config=s" => \$CONFIG,
    "trg-factors=s" => \$TRG_FACTORS,
    "database-config=s" => \$DATABASE,
    "driver-function=s" => \$DRIVER_FUNCTION,
    "fold-config=s" => \$FOLD_CONFIG,
# optional
    "one-feat!" => \$ONE_FEAT,
    "n-best=s" => \$N_BEST,
    "threads=s" => \$THREADS,
    "no-typecheck!" => \$NO_TYPECHECK,
    "check-empty!" => \$CHECK_EMPTY,
    "force!" => \$FORCE,
    "nnlm=s" => \$NNLM,
);

if (not (defined ($WORKING_DIR) && defined($TRAVATAR) && defined($GEOQUERY) 
        && defined ($LETRAC) && defined($CONFIG) && defined($FOLD_CONFIG)
        && defined ($TRG_FACTORS) && defined($DRIVER_FUNCTION) 
        )) 
{
    die "Usage run-tune.pl -working-dir [WD] -geoquery [GEOQUERY] -travatar [TRAVATAR] -travatar-config [CONFIG] -src [SRC] -ref [REF] -trg-factors [TRG_FACTORS] -geoquery [GEOQUERY] -letrac [LETRAC] -database-config [DATABASE] -driver-function [DRIVER_FUNCTION] -fold-config [FOLD_CONFIG] -lamtram [LAMTRAM]"; 
}
if (-d $WORKING_DIR) {
    if ($FORCE) {
        safesystem("rm -rf $WORKING_DIR");
    } else {
        die "Working dir exists: $WORKING_DIR";
    }
}

### Creating Working Directory
print STDERR "===== EXECUTING TUNING =====\n";
 
#### 1. Do the tuning with travatar ####
my $tune_options = $ONE_FEAT ? "-tune-options \"-algorithm lbfgs\"" : "";
my $no_typecheck = $NO_TYPECHECK ? "-no_typecheck" : "";
my $check_empty = $CHECK_EMPTY ? "-check_empty" : "";
my $nnlm = ($NNLM) ? "-nnlm $NNLM" : "";
safesystem("script/pipeline/folds-travatar.pl -lamtram-dir $LAMTRAM -nbest $N_BEST -travatar-config $CONFIG -travatar-dir $TRAVATAR -working-dir $WORKING_DIR -trace -threads $THREADS -trg-factors $TRG_FACTORS -fold-config $FOLD_CONFIG $tune_options $nnlm") or die;

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

