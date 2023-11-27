#!/bin/bash
###############################################################################
#     Aydin Karatas
#     Project Coprolite Viromes
#	  loop_runs.sh 
###############################################################################
cd $HOME/project_coprolite_viromes

script=$1

valid_ori="pal-AWC pal-BEL pal-BMS pal-ENG pal-ITA pal-PER pal-ZAF pal-ZAP \
            ind-DNK ind-ESP ind-USA \
            pre-FJI pre-MDG pre-MEX pre-PER pre-TZA"

for ori in $valid_ori; do
    ./run.sh -s $script -d 8 -c 8 -p $SCRATCH/project_coprolite_viromes -o $ori
done
