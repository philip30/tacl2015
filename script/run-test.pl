#!/usr/bin/env perl
use strict;
use utf8;
use Getopt::Long;
use List::Util qw(sum min max shuffle);
binmode STDIN, ":utf8";
binmode STDOUT, ":utf8";
binmode STDERR, ":utf8";

my ($WORKING_DIR,$CONFIG,$SRC,$REF,$GEOQUERY,$LETRAC,$TRG_FACTORS,$TRAVATAR,$DATABASE,$FORCE,$DRIVER_FUNCTION,$LAMTRAM);

my $THREADS="1";
my $N_BEST="500";
my $NO_TYPECHECK;
my $CHECK_EMPTY;
my $MODEL = "";
my ($NNLM, $NNLM_CONFIG);

GetOptions(
# Required
    "working-dir=s" => \$WORKING_DIR,
    "travatar-config=s" => \$CONFIG,
    "src=s" => \$SRC,
    "ref=s" => \$REF,
    "geoquery=s"=> \$GEOQUERY,
    "letrac=s" => \$LETRAC,
    "lamtram=s" => \$LAMTRAM,
    "trg-factors=s" => \$TRG_FACTORS,
    "travatar=s" => \$TRAVATAR,
    "database-config=s" => \$DATABASE,
# For Experiment need
    "driver-function=s" =>\$DRIVER_FUNCTION,
# Optional
    "n-best=s" => \$N_BEST,
    "threads=s" => \$THREADS,
    "force!" => \$FORCE,
    "no-typecheck!" => \$NO_TYPECHECK,
    "check-empty!" => \$CHECK_EMPTY,
    "nnlm=s" => \$NNLM,
    "nnlm-config=s" => \$NNLM_CONFIG,
);

if (not (defined ($WORKING_DIR) && defined($TRAVATAR) && defined($GEOQUERY) 
        && defined ($LETRAC) && defined($SRC) && defined($REF) && defined($CONFIG)
        && defined ($TRG_FACTORS) && defined($DATABASE) && defined($DRIVER_FUNCTION)
        && defined ($LAMTRAM))) 
{
    die "Usage run-test.pl -working-dir [WD] -geoquery [GEOQUERY] -travatar [TRAVATAR] -travatar-config [CONFIG] -src [SRC] -ref [REF] -trg-factors [TRG_FACTORS] -letrac [LETRAC] -database-config [DATABASE] -driver-function [DRIVER_FUNCTION] -lamtram [LAMTRAM]"; 
}
if (-d $WORKING_DIR) {
    if ($FORCE) {
        safesystem("rm -rf $WORKING_DIR");
    } else {
        die "Working dir exists: $WORKING_DIR";
    }
}

### Creating Working Directory
print STDERR "===== EXECUTING TESTING =====\n";

my $ref_length = (split(/ /,`wc -l $REF`))[0];
safesystem("mkdir -p $WORKING_DIR") or die;

### Execute decoding
safesystem("cp $CONFIG $WORKING_DIR/travatar.ini") or die;

if ($NNLM_CONFIG) {
    safesystem("cp $NNLM_CONFIG $WORKING_DIR/travatar-nnlm.ini") or die;
}

safesystem("$TRAVATAR/src/bin/travatar -threads $THREADS -config_file $WORKING_DIR/travatar.ini -nbest $N_BEST -nbest_out $WORKING_DIR/nbest.txt -trace_out $WORKING_DIR/out.trace -buffer false < $SRC > $WORKING_DIR/out.txt 2> $WORKING_DIR/err.txt") or die;

if ($NNLM) {
    safesystem("script/tune/extract-paraphrase.py < $WORKING_DIR/nbest.txt > $WORKING_DIR/paraphrase.txt") or die;
    safesystem("$LAMTRAM/src/lamtram/lamtram --operation ppl --model_in $NNLM < $WORKING_DIR/paraphrase.txt > $WORKING_DIR/scores.ppl") or die;
    safesystem("script/tune/nnlm-rescore.py --score $WORKING_DIR/scores.ppl --input $WORKING_DIR/nbest.txt --ini $WORKING_DIR/travatar-nnlm.ini") or die; 
}

safesystem("$TRAVATAR/script/mert/nbest-uniq.pl < $WORKING_DIR/nbest.txt | script/test/validate-nbest.py -n $ref_length > $WORKING_DIR/nbest.uniq") or die;
my $no_typecheck = $NO_TYPECHECK ? "-no_typecheck" : "";
my $check_empty = $CHECK_EMPTY ? "-check_empty" : "";
my $stat_generator_cmd = "$LETRAC/stat-generator.py -threads $THREADS -letrac $LETRAC -trg_factors $TRG_FACTORS -geoquery \"swipl -s $GEOQUERY\" -ref $REF -database_config $DATABASE -driver_function $DRIVER_FUNCTION $no_typecheck $check_empty";
safesystem("$stat_generator_cmd -working_dir $WORKING_DIR -input $WORKING_DIR/nbest.uniq > $WORKING_DIR/nbest.stats 2> $WORKING_DIR/nbest.stats.log") or die;
safesystem("paste $WORKING_DIR/nbest.result $WORKING_DIR/nbest.stats > $WORKING_DIR/nbest.stats.res") or die;
safesystem("paste $WORKING_DIR/nbest.reduct $WORKING_DIR/nbest.stats > $WORKING_DIR/nbest.stats.red") or die;
safesystem("script/test/calculate-score.py -i $WORKING_DIR/nbest.stats.res -gs $REF  > $WORKING_DIR/test.result") or die;

# Generating Report 
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
