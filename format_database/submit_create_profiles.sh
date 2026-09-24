#!/bin/bash
###############################################################################
#       Aydin Karatas
#       Project Coprolite Viromes
#       submit_create_profiles.sh
###############################################################################

profiles_dir=$1
cores=2
tot_clusters=$(wc -l < $profiles_dir/clusters.txt)
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
    "${HOME}/project_coprolite_viromes/format_database/create_profiles.sh" $cores $profiles_dir
