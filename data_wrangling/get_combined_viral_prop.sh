###############################################################################
#       Aydin Karatas
#		Project Coprolite Viromes
#		get_combined_viral_prop.sh 
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
prokka_annotations="${project_dir}/genome_annotation"
data_dir="$project_dir/data"
indiv_csv_dir="$data_dir/indiv_viral_prop"
csv_path="$data_dir/viral_prop.csv"

# generate counts with python script
echo "===================================================================================================="
echo "$(timestamp): get_combined_viral_prop: generating viral prop. counts"
echo "===================================================================================================="
python3 data_wrangling/get_combined_viral_prop.py \
	$indiv_csv_dir \
	$csv_path

# check if raw counts was created
if ls $csv_path 1> /dev/null 2>&1; then
	echo "$(timestamp): get_combined_viral_prop: viral prop csv created"
else
	echo "$(timestamp): get_combined_viral_prop: viral prop csv not found"
	exit 1
fi
