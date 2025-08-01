#!/bin/bash
###############################################################################
#     Aydin Karatas
#     Project Coprolite Viromes
#	  run_step.sh 
###############################################################################
cd $HOME/project_coprolite_viromes


script=$1
filename=$(basename "$script")

if [[ $filename =~ ^[0-9]+_ ]]; then
    # run pal samples
    ./run_ori.sh -s $script -d 8 -c 8 -p $SCRATCH/project_coprolite_viromes -o pal-AWC
    ./run_ori.sh -s $script -d 8 -c 8 -p $SCRATCH/project_coprolite_viromes -o pal-BEL
    ./run_ori.sh -s $script -d 8 -c 16 -p $SCRATCH/project_coprolite_viromes -o pal-BMS
    ./run_ori.sh -s $script -d 8 -c 8 -p $SCRATCH/project_coprolite_viromes -o pal-ENG
    ./run_ori.sh -s $script -d 8 -c 8 -p $SCRATCH/project_coprolite_viromes -o pal-ZAF
    ./run_ori.sh -s $script -d 8 -c 8 -p $SCRATCH/project_coprolite_viromes -o pal-ZAP

    # run ind samples
    ./run_ori.sh -s $script -d 8 -c 8 -p $SCRATCH/project_coprolite_viromes -o ind-DNK
    ./run_ori.sh -s $script -d 8 -c 8 -p $SCRATCH/project_coprolite_viromes -o ind-ESP
    ./run_ori.sh -s $script -d 8 -c 8 -p $SCRATCH/project_coprolite_viromes -o ind-USA

    # run non-ind samples
    ./run_ori.sh -s $script -d 8 -c 8 -p $SCRATCH/project_coprolite_viromes -o pre-FJI
    ./run_ori.sh -s $script -d 8 -c 8 -p $SCRATCH/project_coprolite_viromes -o pre-MDG
    ./run_ori.sh -s $script -d 8 -c 8 -p $SCRATCH/project_coprolite_viromes -o pre-MEX
    ./run_ori.sh -s $script -d 8 -c 8 -p $SCRATCH/project_coprolite_viromes -o pre-PER
    ./run_ori.sh -s $script -d 8 -c 8 -p $SCRATCH/project_coprolite_viromes -o pre-TZA
elif [[ $filename =~ ^[0-9]+a_ ]]; then
    # run auxilliar script that is not specific to an origin
    ./run_ori.sh -s $script -d 8 -c 4 -p $SCRATCH/project_coprolite_viromes -o all
fi
