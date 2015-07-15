#!/usr/bin/perl

use strict;
use utf8;
use Getopt::Long;
use List::Util qw(sum min max shuffle);
binmode STDIN, ":utf8";
binmode STDOUT, ":utf8";
binmode STDERR, ":utf8";

my ($REF, $TRAVATAR_CONFIG, $TRAVATAR_DIR, $WORKING_DIR, $TRAVATAR, $DECODER_OPTIONS, $LAMTRAM);
my ($STAT_GENERATOR, $TRACE);
my ($NNLM);

my $MODEL = "rec40-uadagrad-r40-c3-s200";
my $TUNE_OPTIONS = ""; # Other options to pass to batch-tune
my $MAX_ITERS = 20;
my $MIN_DIFF = 0.001;
my $CAND_TYPE = "nbest"; # Can be set to "forest" for forest-based mert
my $IN_FORMAT = "word"; # The format of the input
my $NBEST = 200;
my $TRG_FACTORS = 1; # The number of target factors
my $THREADS = 1; # The number of threads to use
my $FOLD_CONFIG = ""; # The config to run n-folds cross validation
my $DECODER_OPTIONS="";
GetOptions(
    # Necessary
    "travatar-dir=s" => \$TRAVATAR_DIR,
    "working-dir=s" => \$WORKING_DIR,
    "travatar-config=s" => \$TRAVATAR_CONFIG,
    "lamtram-dir=s" => \$LAMTRAM,
    # Options
    "travatar=s" => \$TRAVATAR,
    "decoder-options=s" => \$DECODER_OPTIONS,
    "tune-options=s" => \$TUNE_OPTIONS,
    "max-iters=i" => \$MAX_ITERS,
    "nbest=i" => \$NBEST,
    "trace!" => \$TRACE,
    "threads=i" => \$THREADS,
    "trg-factors=i" => \$TRG_FACTORS,
    "stat-generator=s" => \$STAT_GENERATOR,
    "fold-config=s" => \$FOLD_CONFIG,
    "nnlm=s" => \$NNLM,
);

# Sanity check
if ((not $TRAVATAR_DIR) or (not $WORKING_DIR) or not ($TRAVATAR_CONFIG) or not ($FOLD_CONFIG)) {
    die "Must specify travatar-config, travatar-dir, working-dir, and fold-config";
}
($DECODER_OPTIONS =~ /(in_format|trg_factors)/) and die "Travatar's $1 should not be specified through -decoder-options, but through the option of mert-travatar.pl";
$TRAVATAR = "$TRAVATAR_DIR/src/bin/travatar" if not $TRAVATAR;

if(@ARGV != 0) {
    print STDERR "Usage: $0 -travatar-dir /path/to/travatar -working-dir /path/to/workingdir -travatar-config initial-travatar.ini -fold-config fold-configs\n";
    exit 1;
}

# Make the working directory
safesystem("mkdir $WORKING_DIR") or die "couldn't mkdir";

safesystem("cp $TRAVATAR_CONFIG $WORKING_DIR/run1.ini") or die;
my %fold_config = load_fold_config($FOLD_CONFIG);
my $folds = scalar keys %fold_config;

# Find the weights contained in the model
my %init_weights = load_weights($TRAVATAR_CONFIG);
my $weight_cnt = keys %init_weights;
die "Couldn't find any weights in the model" if not $weight_cnt;
# `Print these if needed for batch-tune
open FILE0, ">:utf8", "$WORKING_DIR/run1.weights" or die "Couldn't open $WORKING_DIR/run1.weights\n";
while(my ($k,$v) = each(%init_weights)) { print FILE0 "$k=$v\n"; }
close FILE0;

# Do the outer loop
my ($iter_last, $prev, $next);
foreach my $iter (1 .. $MAX_ITERS) {
    $iter_last = $iter;
    $prev = "$WORKING_DIR/run$iter";
    $next = "$WORKING_DIR/run".($iter+1);

    # Decoding
    my $CAND_OPTIONS;
    my $format = ($IN_FORMAT ? "-in_format $IN_FORMAT" : "");
    my @refs;

    foreach my $n (sort keys %fold_config) {
        $CAND_OPTIONS = "-nbest $NBEST -nbest_out $prev-fold-$n.nbest";
        # Do the decoding
        my $trace = ($TRACE ? "-trace_out $prev-fold-$n.trace -buffer false" : "");
        my $lm_file = ""; 
        if (exists $fold_config{$n}->{"lm_file"}) {
            $lm_file = sprintf("-lm_file %s", $fold_config{$n}->{"lm_file"});
        }
        
        safesystem(sprintf("$TRAVATAR -threads $THREADS $format $trace -trg_factors $TRG_FACTORS -config_file $prev.ini -tm_file %s $DECODER_OPTIONS $CAND_OPTIONS $lm_file < %s > $prev-fold-$n.out 2> $prev-fold-$n.err", $fold_config{$n}->{"tm_file"}, $fold_config{$n}->{"src"})) or die "couldn't decode";
        push @refs, $fold_config{$n}->{"ref"};
    }

    my $merge_nbest = join(" ", map { "$prev-fold-$_.nbest" } (0..$folds-1));
    my $refs = join(" ", @refs);
   
    $REF = "$prev.ref";
    safesystem("script/tune/folds-ref.py --nbest $merge_nbest --ref $refs --nbest_out $WORKING_DIR/run$iter.nbest --ref_out $REF") or die "Couldn't merge n-best and create reference file.";

    # Tuning
    my $nbests = join(" ", map { "$WORKING_DIR/run$_.uniq" } (1 .. $iter-1));
    safesystem("$TRAVATAR_DIR/script/mert/nbest-uniq.pl $nbests < $WORKING_DIR/run$iter.nbest > $WORKING_DIR/run$iter.uniq");
    safesystem("$STAT_GENERATOR -trg_factors $TRG_FACTORS -threads $THREADS -input $WORKING_DIR/run$iter.uniq -ref $REF > $WORKING_DIR/run$iter.stats 2> $prev.stats.log") or die "Could not run stat generator: $STAT_GENERATOR";
    $nbests = join(",", map { "$WORKING_DIR/run$_.uniq" } (1 .. $iter));
    my $stats = join(",", map { "$WORKING_DIR/run$_.stats" } (1 .. $iter));
    safesystem("$TRAVATAR_DIR/src/bin/batch-tune -threads $THREADS -nbest $nbests -stat_in $stats -eval \"ribes\" -weight_in $prev.weights $TUNE_OPTIONS $REF > $next.weights 2> $prev.tune.log") or die "batch-tune failed";
    safesystem("$TRAVATAR_DIR/script/mert/update-weights.pl -weights $next.weights $prev.ini > $next.ini") or die "couldn't make init opt";
    safesystem("sed -i \"/=0\$/d\" $next.ini");
    my %wprev = load_weights("$prev.ini");
    my %wnext = load_weights("$next.ini");
    my $diff = 0;
    for(keys %wprev) { $diff += abs($wprev{$_} - $wnext{$_}); }
    last if($diff < $MIN_DIFF);
}

safesystem("$TRAVATAR_DIR/script/mert/update-weights.pl -model $next.ini $TRAVATAR_CONFIG > $WORKING_DIR/travatar.ini") or die "couldn't make init opt";
safesystem("cat $prev.tune.log | grep \"Best\" > $WORKING_DIR/tune.best");
safesystem("sed -i \"/=0\$/d\" $WORKING_DIR/travatar.ini");

# DOING THE NNLM
if ($NNLM) {
    my $iter = $iter_last + 1;
    
    $prev = "$WORKING_DIR/run$iter";
    $next = "$WORKING_DIR/run".($iter+1);

    # Decoding
    my $CAND_OPTIONS;
    my $format = ($IN_FORMAT ? "-in_format $IN_FORMAT" : "");
    my @refs;

    foreach my $n (sort keys %fold_config) {
        $CAND_OPTIONS = "-nbest $NBEST -nbest_out $prev-fold-$n.nbest";
        # Do the decoding
        my $trace = ($TRACE ? "-trace_out $prev-fold-$n.trace -buffer false" : "");
        my $lm_file = ""; 
        if (exists $fold_config{$n}->{"lm_file"}) {
            $lm_file = sprintf("-lm_file %s", $fold_config{$n}->{"lm_file"});
        }
        
        safesystem(sprintf("$TRAVATAR -threads $THREADS $format $trace -trg_factors $TRG_FACTORS -config_file $prev.ini -tm_file %s $DECODER_OPTIONS $CAND_OPTIONS $lm_file < %s > $prev-fold-$n.out 2> $prev-fold-$n.err", $fold_config{$n}->{"tm_file"}, $fold_config{$n}->{"src"})) or die "couldn't decode";
        push @refs, $fold_config{$n}->{"ref"};
    
        # NNLM Rescoring
        safesystem("script/tune/extract-paraphrase.py < $prev-fold-$n.nbest > $prev-fold-$n.paraphrase") or die;
        
        my @nnlm = split(/\//, $NNLM);
        my @last = split(/-/, $nnlm[$#nnlm]);
        splice @last, 2, 0, $n;
        $nnlm[$#nnlm] = join("-", @last);
        my $nnlm_model = join("/", @nnlm);
        
        safesystem("$LAMTRAM/src/lamtram/lamtram --operation ppl --model_in $nnlm_model < $prev-fold-$n.paraphrase > $prev-fold-$n.ppl") or die;
        safesystem("script/tune/nnlm-rescore.py --score $prev-fold-$n.ppl --input $prev-fold-$n.nbest --ini $prev.ini") or die;       
    }

    my $merge_nbest = join(" ", map { "$prev-fold-$_.nbest" } (0..$folds-1));
    my $refs = join(" ", @refs);
   
    $REF = "$prev.ref";
    safesystem("script/tune/folds-ref.py --nbest $merge_nbest --ref $refs --nbest_out $WORKING_DIR/run$iter.nbest --ref_out $REF") or die "Couldn't merge n-best and create reference file.";

    # Tuning
    safesystem("$TRAVATAR_DIR/script/mert/nbest-uniq.pl < $WORKING_DIR/run$iter.nbest > $WORKING_DIR/run$iter.uniq");
    safesystem("$STAT_GENERATOR -trg_factors $TRG_FACTORS -threads $THREADS -input $WORKING_DIR/run$iter.uniq -ref $REF > $WORKING_DIR/run$iter.stats 2> $prev.stats.log") or die "Could not run stat generator: $STAT_GENERATOR";
    safesystem("$TRAVATAR_DIR/src/bin/batch-tune -threads $THREADS -nbest $WORKING_DIR/run$iter.uniq -stat_in $WORKING_DIR/run$iter.stats -eval \"ribes\" -weight_in $prev.weights $TUNE_OPTIONS $REF > $next.weights 2> $prev.tune.log") or die "batch-tune failed";
    safesystem("$TRAVATAR_DIR/script/mert/update-weights.pl -weights $next.weights $prev.ini > $next.ini") or die "couldn't make init opt";

    safesystem("$TRAVATAR_DIR/script/mert/update-weights.pl -model $next.ini $TRAVATAR_CONFIG > $WORKING_DIR/travatar-nnlm.ini") or die "couldn't make init opt";
    safesystem("sed -i \"/=0\$/d\" $WORKING_DIR/travatar-nnlm.ini");
    safesystem("cat $prev.tune.log | grep \"Best\" > $WORKING_DIR/tune-nnlm.best");
}

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

# Load weights
sub load_weights {
    my $fname = shift;
    open FILE0, "<:utf8", $fname or die "Couldn't open $fname\n";
    my %ret;
    while(<FILE0>) {
        chomp;
        if(/^\[weight_vals\]$/) {
            while(<FILE0>) {
                chomp;
                last if not $_;
                my ($k, $v) = split(/=/);
                $ret{$k} = $v;
            }
            last;
        }
    }
    close FILE0;
    return %ret;
}

# Load n-folds cross validation config
sub load_fold_config {
    my $configs = shift;
    my @config_files = split(",", $configs);
    my %ret;
    my $i=0;
    foreach my $config_file (@config_files) {
        open FILE0, "<:utf8", $config_file or die "Couldn't open $config_file\n";
        while(<FILE0>) {
            chomp;
            last if not $_;
            my ($k, $v) = split(/=/);
            if (not $k =~ /^(src|ref|tm_file|lm_file)/) {
                close FILE0;
                die "$config_file has an unknown configuration: $k";
            }
            $ret{$i}{$k} = $v;
        }
        close FILE0;
        ++$i;
    }
    return %ret;
}
