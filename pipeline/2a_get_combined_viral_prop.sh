#!/bin/bash
###############################################################################
#       Aydin Karatas
#		Project Coprolite Viromes
#		2a_get_combined_viral_prop.sh 
###############################################################################
cd $HOME/project_coprolite_viromes
for FILE in general_bash_functions/* ; do source $FILE ; done
source /u/local/Modules/default/init/modules.sh
module load python
source $python_env


# define inputs variables
origin=$1
project_dir=$2
num_cores=$3

# define directories and file
contigs_dir="${project_dir}/contigs"
data_dir="$project_dir/data"
indiv_csv_dir_all="$data_dir/indiv_viral_prop_all"
indiv_csv_dir_no_hypo="$data_dir/indiv_viral_prop_no_hypo"
csv_path_all="$data_dir/viral_prop_all.csv"
csv_path_no_hypo="$data_dir/viral_prop_no_hypo.csv"

# generate viral proportions for both including and not including hypothetical proteins
echo "===================================================================================================="
echo "$(timestamp): 2a_get_combined_viral_prop: generating viral prop. counts"
echo "===================================================================================================="
mkdir -p $data_dir
python3 data_wrangling/get_combined_data.py \
	$indiv_csv_dir_all \
	$csv_path_all

python3 data_wrangling/get_combined_data.py \
	$indiv_csv_dir_no_hypo \
	$csv_path_no_hypo

# check if raw counts was created
if ls $csv_path_all 1> /dev/null 2>&1; then
	echo "$(timestamp): 2a_get_combined_viral_prop: viral prop all csv created"
else
	echo "$(timestamp): 2a_get_combined_viral_prop: ERROR! viral prop csv not found"
	exit 1
fi

if ls $csv_path_no_hypo 1> /dev/null 2>&1; then
	echo "$(timestamp): 2a_get_combined_viral_prop: viral prop no hypo csv created"
else
	echo "$(timestamp): 2a_get_combined_viral_prop: ERROR! viral prop no hypo csv not found"
	exit 1
fi
