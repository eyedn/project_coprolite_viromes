#!/bin/bash
###############################################################################
#       Aydin Karatas
#       Project Coprolite Viromes
#       submit_VFDB_extract_clusters.sh
###############################################################################


set -euo pipefail

code_dir="${VIROME_CODE_DIR:-$HOME/project_coprolite_viromes}"
source "$code_dir/general_bash_functions/environment.sh"
activate_environment python || exit 1

# run python script to create separate fasta files for each cluster
raw_fasta="$SCRATCH/references/VFDB_setB_pro_20260923.fas"
clean_fasta="$SCRATCH/references/VFDB_setB_pro_20260923.ascii.fas"
profiles_dir="$SCRATCH/VFDB_setB_pro_20260923_profiles"

LC_ALL=C tr '\240' ' ' < "$raw_fasta" > "$clean_fasta"

if [[ -e "$profiles_dir" ]]; then
    echo "Profile directory already exists: $profiles_dir" >&2
    exit 1
fi

mkdir "$profiles_dir"

python3 "$code_dir/format_database/VFDB_extract_clusters.py" \
    "$clean_fasta" \
    "$profiles_dir" \
    "$profiles_dir/clusters.txt"
