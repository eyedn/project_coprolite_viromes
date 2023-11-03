#!/bin/bash
source /u/local/Modules/default/init/modules.sh
module load python


# run python script to create separate fasta files for each cluster
python3 VFDB_extract_clusters.py \
    $SCRATCH/references/VFDB.fas \
    $SCRATCH/VFDB_cluster_profiles \
    $SCRATCH/VFDB_cluster_profiles/clusters.txt