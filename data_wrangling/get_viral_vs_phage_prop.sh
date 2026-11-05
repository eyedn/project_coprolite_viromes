#!/bin/bash
###############################################################################
#       Aydin Karatas
#       Project Coprolite Viromes
#       get_viral_vs_phage_prop.sh
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

# define sample variable
sample_record=$(select_record \
    "${project_dir}/samples/${origin}_samples.txt") || exit 2
read -r sample accession_ids <<< "$sample_record"

# define directories and file
phage_predict_dir="$project_dir/phage_predictions"
viral_prop_all_dir="$project_dir/data/indiv_viral_prop_all"
data_dir="$project_dir/data/indiv_viral_vs_phage_prop"
phage_predict="$phage_predict_dir/${origin}_${sample}_prediction/out/phamer_prediction.csv"
viral_prop_all="$viral_prop_all_dir/${origin}_${sample}_viral_prop_all.csv"
csv_path="$data_dir/${origin}_${sample}_viral_prop_all.csv"

# check if download was already complete for this sample
if ls $phage_predict 1> /dev/null 2>&1; then
	echo "$(timestamp): get_viral_vs_phage_prop: phage pred file found"
else
	echo "$(timestamp): get_viral_vs_phage_prop: ERROR! phage pred file not found"
	exit 1
fi
if ls $viral_prop_all 1> /dev/null 2>&1; then
	echo "$(timestamp): get_viral_vs_phage_prop: viral prop file found"
else
	echo "$(timestamp): get_viral_vs_phage_prop: ERROR! viral prop file not found"
	exit 1
fi

# generate counts with python script
echo "===================================================================================================="
echo "$(timestamp): get_viral_vs_phage_prop: generating viral vs phage prop"
echo "===================================================================================================="
mkdir -p $data_dir
python3 data_wrangling/get_viral_vs_phage_prop.py \
	$viral_prop_all \
	$phage_predict \
	$csv_path

# check if viral prop csv's created
if ls $csv_path 1> /dev/null 2>&1; then
	echo "$(timestamp): get_viral_vs_phage_prop: viral vs phage prop all csv created"
else
	echo "$(timestamp): get_viral_vs_phage_prop: ERROR! viral vs phage prop all csv not found"
	exit 1
fi
