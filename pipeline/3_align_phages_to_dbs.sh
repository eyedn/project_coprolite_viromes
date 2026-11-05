#!/bin/bash
###############################################################################
#       Aydin Karatas
#       Project Coprolite Viromes
#       3_align_phages_to_dbs.sh
###############################################################################


code_dir="${VIROME_CODE_DIR:-$HOME/project_coprolite_viromes}"
source "$code_dir/general_bash_functions/slurm.sh"
validate_cpus "${3:-}" || exit 2


cd "${VIROME_CODE_DIR:-$HOME/project_coprolite_viromes}" || exit 1


origin=$1
origin_parent=$2
num_cores=$3 

# align phages to vfdb
. hmm_alignment/vf_alignment.sh "$origin" "$origin_parent" "$num_cores" 

# align phages to cazy db
# . hmm_alignment/cazy_alignment.sh "$origin" "$origin_parent" "$num_cores" 
