###############################################################################
#       Aydin Karatas
#		Project Coprolite Viromes
#		2_get_combined_viral_prop.sh 
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
contigs_dir="${project_dir}/contigs"
data_dir="$project_dir/data"
indiv_csv_dir="$data_dir/indiv_viral_prop"
csv_path="$data_dir/viral_prop.csv"

# generate counts with python script
echo "===================================================================================================="
echo "$(timestamp): 2_get_combined_viral_prop: generating viral prop. counts"
echo "===================================================================================================="
python3 data_wrangling/get_combined_data.py \
	$indiv_csv_dir \
	$csv_path

# check if raw counts was created
if ls $csv_path 1> /dev/null 2>&1; then
	echo "$(timestamp): 2_get_combined_viral_prop: viral prop csv created"
else
	echo "$(timestamp): 2_get_combined_viral_prop: viral prop csv not found"
	exit 1
fi
