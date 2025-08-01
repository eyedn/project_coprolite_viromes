#!/bin/bash
###############################################################################
#     Aydin Karatas
#     Project Coprolite Viromes
#     run_step.sh 
###############################################################################
cd $HOME/project_coprolite_viromes

script=$1
filename=$(basename "$script")

if [[ $filename =~ ^[0-9]+_ ]]; then
    # initialize variable for dependency tracking
    last_job_id=""

    # ordered origins
    origins=( pal-AWC pal-BEL pal-BMS pal-ENG pal-ZAF pal-ZAP \
            ind-DNK ind-ESP ind-USA \
            pre-FJI pre-MDG pre-MEX pre-PER pre-TZA )

    for ori in "${origins[@]}"; do
        if [[ -z "$last_job_id" ]]; then
            echo "submitting $ori with no dependency"
            jobid=$(./run_ori.sh -s "$script" -d 8 -c 8 -p "$SCRATCH/project_coprolite_viromes" -o "$ori")
            echo "submitted $jobid for $ori with no dependency"
        else
            jobid=$(./run_ori.sh -s "$script" -d 8 -c 8 -p "$SCRATCH/project_coprolite_viromes" -o "$ori" -h "$last_job_id")
            echo "submitted $jobid for $ori with dependency $jobid"
        fi
        last_job_id="$jobid"
    done

elif [[ $filename =~ ^[0-9]+a_ ]]; then
    # run auxiliary script independently
    ./run_ori.sh -s $script -d 8 -c 4 -p $SCRATCH/project_coprolite_viromes -o all
fi
