#!/bin/bash


fasta="/u/scratch/a/ayd1n/reference_fas/VFDB_setB_pro.fas"
cores=2
qsub \
    -cwd \
    -N "create_profiles" \
    -j y \
    -l h_rt=24:00:00,h_data=8G \
    -o $SCRATCH/joblogs/create_profiles/ \
    -pe shared $cores \
    -M $USER@mail \
    -m a \
    -t 1-$(grep ">" VFDB_setB_pro.fas | wc -l):1 \
    "/u/home/a/ayd1n/project_coprolite_viromes/VFDB_create_profiles.sh" $fasta $cores
