#!/bin/bash


cores=2
tot_clusters=$(wc -l < $SCRATCH/VFDB_cluster_profiles/clusters.txt)
qsub \
    -cwd \
    -N "create_profiles" \
    -j y \
    -l h_rt=24:00:00,h_data=8G \
    -o $SCRATCH/joblogs/create_profiles/ \
    -pe shared $cores \
    -M $USER@mail \
    -m a \
    -t 1-$tot_clusters:1 \
    /u/home/a/ayd1n/project_coprolite_viromes/format_VFDB/VFDB_create_profiles.sh $cores
