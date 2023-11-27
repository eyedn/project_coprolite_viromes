#!/bin/bash
##############################################################################
#       Aydin Karatas
#		Project Coprolite Viromes
#		3b_5_get_counts_bac_ec.sh 
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
prokka_annotations="${project_dir}/genome_annotation"
data_dir="$project_dir/data"
search_dir="$prokka_annotations/*bac_on_phage"
gff_list="$data_dir/bac_on_phage_ec_counts_tmp.txt"
csv_path="$data_dir/bac_on_phage_ec_counts.csv"

# generate counts with python script
echo "===================================================================================================="
echo "$(timestamp): 3b_5_get_counts_bac_ec: generating bacterial gene counts"
echo "===================================================================================================="
# create a list of all files to generate counts from
mkdir -p $data_dir
ls $search_dir/*gff.gz > $gff_list
echo "$(timestamp): 3b_5_get_counts_bac_ec: generated file of all file paths needed"
echo "$(timestamp): 3b_5_get_counts_bac_ec: using the following files:"
cat $gff_list

python3 data_wrangling/collect_ec_counts.py \
	$gff_list \
	$csv_path
rm $gff_list

# check if raw counts was created
if ls $csv_path 1> /dev/null 2>&1; then
	echo "$(timestamp): 3b_5_get_counts_bac_ec: bacterial gene counts csv created"
else
	echo "$(timestamp): 3b_5_get_counts_bac_ec: ERROR! bacterial gene counts csv not found"
	exit 1
fi
