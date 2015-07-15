#!/bin/bash

for x in 0 1 2 3 4 5 6 7 8 9; do
    script/run-test.pl -working-dir temp/geotune-geoall-testing/fold-$x -geoquery metadata/geoquery/eval.pl -travatar ~/dev/travatar -travatar-config temp/geotune-geoall-testing/ini/fold-$x.ini -src data/keyword-shuffle/run-0/fold-$x/test.sent -ref data/keyword-shuffle/run-0/fold-$x/test.mrl.time.ref -trg-factors 2 -letrac ~/dev/letrac -database-config config/mysql.config -driver-function execute_query
done
