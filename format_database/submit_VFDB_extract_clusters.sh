#!/bin/bash
###############################################################################
#       Aydin Karatas
#       Project Coprolite Viromes
#       submit_VFDB_extract_clusters.sh
###############################################################################
source /u/local/Modules/default/init/modules.sh
module load python


# run python script to create separate fasta files for each cluster
python3 VFDB_extract_clusters.py \
    $SCRATCH/references/VFDB_setA_pro_20230917.fas \
    $SCRATCH/VFDB_cluster_profiles \
    $SCRATCH/VFDB_cluster_profiles/clusters.txt