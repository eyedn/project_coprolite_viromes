#!/bin/bash
source /u/local/Modules/default/init/modules.sh

orf_files_pat=

# Directory to store the clustered ORFs
CLUSTERED_DIR="$SCRATCH/Clustered_ORFs"
mkdir -p $CLUSTERED_DIR

# Path to CD-HIT
CDHIT="/path/to/cd-hit"

# Concatenate all ORF files into one file for clustering
cat $ORF_DIR/*.fas > $CLUSTERED_DIR/all_orfs.fas

# Run CD-HIT to cluster ORFs at 90% similarity threshold (adjust as needed)
$CDHIT -i $CLUSTERED_DIR/all_orfs.fas -o $CLUSTERED_DIR/clustered_orfs -c 0.9 -n 5

# Now, split the clustered ORFs into individual files
python split_clusters.py $CLUSTERED_DIR/clustered_orfs $CLUSTERED_DIR

# Your further processing (MSA and HMM) can then use these clustered ORFs
