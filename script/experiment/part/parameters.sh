#!/bin/bash

# Program Parameter
p_pialign="-pialign $PIALIGN"
p_letrac="-letrac $LETRAC"
p_travatar="-travatar $TRAVATAR"
p_lamtram="-lamtram $LAMTRAM"
p_trg_factors="-trg-factors $trg_factors"
p_geoquery="-geoquery $geoquery"
p_threads="-threads $threads"
p_nbest="-n-best $N_BEST"

# Training-flag
p_compose_size="-max-size 4"                 # size for rule composition
p_manual_align="-manual-align metadata/geoquery/supervised/manual-align.txt"
p_verbose=
p_xeval=
p_kb="-kb metadata/geoquery/geobase.rule"
p_del_file="-del-file $data/del-sent-all.rules"
p_additional_rule="-additional-rule metadata/geoquery/supervised/initial-rule.txt"
p_training="-force $p_trg_factors $p_letrac $p_manual_align $p_kb $p_verbose $p_xeval $p_pialign $p_del_file $p_3_sync $p_additional_rule $p_stem $p_shuffle $p_compose_size"

# Tune-flag
p_database="-database-config config/mysql.config"
p_driver="-driver-function $driver"
p_tune="-force $p_travatar $p_trg_factors $p_geoquery $p_threads $p_database $p_nbest $p_letrac $p_driver $p_notypecheck $p_empty $p_lamtram"

# Test-flag
p_test="$p_tune"

