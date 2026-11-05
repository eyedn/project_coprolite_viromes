#!/bin/bash
###############################################################################
#       Aydin Karatas
#       Project Coprolite Viromes
#       collect_all_ec_counts.sh
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
prokka_annotations="${project_dir}/genome_annotation"
data_dir="$project_dir/data"
search_dir="$prokka_annotations/*all"
gff_list="$data_dir/all_ec_counts_tmp.txt"
csv_path="$data_dir/all_ec_counts.csv"

# create a list of all files to generate counts from
ls $search_dir/*gff.gz > $gff_list
echo "$(timestamp): collect_all_ec_counts: generated file of all file paths needed"
echo "$(timestamp): collect_all_ec_counts: using the following files:"
cat $gff_list

# generate counts with python script
echo "===================================================================================================="
echo "$(timestamp): collect_all_ec_counts: generating bacterial gene counts"
echo "===================================================================================================="
mkdir -p $data_dir
python3 data_wrangling/collect_ec_counts.py \
	$gff_list \
	$csv_path
rm $gff_list

# check if raw counts was created
if ls $csv_path 1> /dev/null 2>&1; then
	echo "$(timestamp): collect_all_ec_counts: bacterial gene counts csv created"
else
	echo "$(timestamp): collect_all_ec_counts: ERROR! bacterial gene counts csv not found"
	exit 1
fi
