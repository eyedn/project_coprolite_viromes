#!/usr/bin/env bash
###############################################################################
#       Aydin Karatas
#       Project Coprolite Viromes
#       submit_create_profiles.sh
###############################################################################


set -euo pipefail
export VIROME_CODE_DIR="${VIROME_CODE_DIR:-$HOME/project_coprolite_viromes}"
source "$VIROME_CODE_DIR/general_bash_functions/slurm.sh"
profiles_dir=$1
cores=2
tot_clusters=$(manifest_count "$profiles_dir/clusters.txt")
submit_slurm create_profiles "$SCRATCH/joblogs/create_profiles" \
    "$tot_clusters" "$cores" 8 FAIL \
    "$VIROME_CODE_DIR/format_database/create_profiles.sh" \
    "$cores" "$profiles_dir"
