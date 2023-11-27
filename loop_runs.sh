#!/bin/bash
###############################################################################
#     Aydin Karatas
#     Project Coprolite Viromes
#	  loop_runs.sh 
###############################################################################
cd $HOME/project_coprolite_viromes

script=$1

# run pal samples
./run.sh -s $script -d 8 -c 8 -p $SCRATCH/project_coprolite_viromes -o pal-AWC
./run.sh -s $script -d 8 -c 8 -p $SCRATCH/project_coprolite_viromes -o pal-BEL
./run.sh -s $script -d 8 -c 16 -p $SCRATCH/project_coprolite_viromes -o pal-BMS
./run.sh -s $script -d 8 -c 8 -p $SCRATCH/project_coprolite_viromes -o pal-ENG
./run.sh -s $script -d 8 -c 8 -p $SCRATCH/project_coprolite_viromes -o pal-ZAF
./run.sh -s $script -d 8 -c 8 -p $SCRATCH/project_coprolite_viromes -o pal-ZAP

# run ind samples
./run.sh -s $script -d 8 -c 8 -p $SCRATCH/project_coprolite_viromes -o ind-DNK
./run.sh -s $script -d 8 -c 8 -p $SCRATCH/project_coprolite_viromes -o ind-ESP
./run.sh -s $script -d 8 -c 8 -p $SCRATCH/project_coprolite_viromes -o ind-USA

# run non-ind samples
./run.sh -s $script -d 8 -c 8 -p $SCRATCH/project_coprolite_viromes -o pre-FJI
./run.sh -s $script -d 8 -c 8 -p $SCRATCH/project_coprolite_viromes -o pre-MDG
./run.sh -s $script -d 8 -c 8 -p $SCRATCH/project_coprolite_viromes -o pre-MEX
./run.sh -s $script -d 8 -c 8 -p $SCRATCH/project_coprolite_viromes -o pre-PER
./run.sh -s $script -d 8 -c 8 -p $SCRATCH/project_coprolite_viromes -o pre-TZA
