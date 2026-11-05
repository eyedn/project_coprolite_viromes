#!/bin/bash
###############################################################################
#       Aydin Karatas
#       Project Coprolite Viromes
#       1a_get_combined_contig_stats.sh
###############################################################################


code_dir="${VIROME_CODE_DIR:-$HOME/project_coprolite_viromes}"
source "$code_dir/general_bash_functions/slurm.sh"
validate_cpus "${3:-}" || exit 2


cd "${VIROME_CODE_DIR:-$HOME/project_coprolite_viromes}" || exit 1
for FILE in general_bash_functions/* ; do source $FILE ; done
activate_environment python || exit 1


# define inputs variables
origin=$1
project_dir=$2
num_cores=$3

# define directories and file
contigs_dir="${project_dir}/contigs"
data_dir="$project_dir/data"
indiv_csv_dir="$data_dir/indiv_contig_stats"
csv_path="$data_dir/contig_stats.csv"

# generate counts with python script
echo "===================================================================================================="
echo "$(timestamp): 1a_get_combined_contig_stats: combining all contig stats"
echo "===================================================================================================="
mkdir -p $data_dir
python3 data_wrangling/get_combined_data.py \
	$indiv_csv_dir \
	$csv_path

# check if raw counts was created
if ls $csv_path 1> /dev/null 2>&1; then
	echo "$(timestamp): 1a_get_combined_contig_stats: stats csv created"
else
	echo "$(timestamp): 1a_get_combined_contig_stats: ERROR! stats csv not found"
	exit 1
fi
