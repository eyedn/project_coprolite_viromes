#!/bin/bash
###############################################################################
#       Aydin Karatas
#       Project Coprolite Viromes
#       1_download_and_assembly.sh
###############################################################################


code_dir="${VIROME_CODE_DIR:-$HOME/project_coprolite_viromes}"
source "$code_dir/general_bash_functions/slurm.sh"
validate_cpus "${3:-}" || exit 2


cd "${VIROME_CODE_DIR:-$HOME/project_coprolite_viromes}" || exit 1


origin=$1
origin_parent=$2
num_cores=$3

# call download and pre-processing script
. download/download.sh "$origin" "$origin_parent" "$num_cores"

# call assembly script
. megahit_assembly/assembly.sh "$origin" "$origin_parent" "$num_cores"

# get contig stats
. data_wrangling/get_indiv_contig_stats.sh "$origin" "$origin_parent" "$num_cores"
