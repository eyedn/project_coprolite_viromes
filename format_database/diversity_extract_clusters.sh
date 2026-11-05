#!/bin/bash
###############################################################################
#       Aydin Karatas
#       Project Coprolite Viromes
#       diversity_extract_clusters.sh
###############################################################################


set -euo pipefail
code_dir="${VIROME_CODE_DIR:-$HOME/project_coprolite_viromes}"
source "$code_dir/general_bash_functions/environment.sh"
if [[ -z ${ORF_DIR:-} || ! -x /path/to/cd-hit ]]; then
    echo 'optional diversity sketch needs ORF_DIR and a configured CD-HIT path' >&2
    exit 1
fi
activate_environment msa

orf_files_pat=

# directory to store the clustered ORFs
CLUSTERED_DIR="$SCRATCH/Clustered_ORFs"
mkdir -p $CLUSTERED_DIR

# path to CD-HIT
CDHIT="/path/to/cd-hit"

# concatenate all ORF files into one file for clustering
cat $ORF_DIR/*.fas > $CLUSTERED_DIR/all_orfs.fas

# run CD-HIT to cluster ORFs at 90% similarity threshold (adjust as needed)
$CDHIT -i $CLUSTERED_DIR/all_orfs.fas -o $CLUSTERED_DIR/clustered_orfs -c 0.9 -n 5

# now, split the clustered ORFs into individual files
python split_clusters.py $CLUSTERED_DIR/clustered_orfs $CLUSTERED_DIR

# your further processing (MSA and HMM) can then use these clustered ORFs
