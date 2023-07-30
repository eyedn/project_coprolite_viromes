###############################################################################
#       Aydin Karatas
#		Project Coprolite Viromes
#		collect_families_counts.sh 
###############################################################################
#!/bin/bash
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
data_dir="${project_dir}/data"
predict_dir="${project_dir}/phage_predictions"
search_dir="$predict_dir/*/out"
search_file="phagcn_prediction.csv"
predict_list="$data_dir/families_counts_tmp.txt"
csv_path="$data_dir/families_counts.csv"

# create a list of all files to generate counts from
ls $search_dir/$search_file > $predict_list
echo "$(timestamp): collect_families_counts: generated file of all file paths needed"
echo "$(timestamp): collect_families_counts: using the following files:"
cat $predict_list

# generate counts with python script
echo "===================================================================================================="
echo "$(timestamp): collect_families_counts: generating families counts"
echo "===================================================================================================="
python3 data_wrangling/collect_phred_counts.py \
	$predict_list \
	$csv_path
rm $predict_list

# check if raw counts was created
if ls $csv_path 1> /dev/null 2>&1; then
	echo "$(timestamp): collect_families_counts: families counts csv created"
else
	echo "$(timestamp): collect_families_counts: families counts csv not found"
	exit 1
fi