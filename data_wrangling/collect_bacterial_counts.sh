###############################################################################
#       Aydin Karatas
#		Project Coprolite Viromes
#		collect_bacterial_counts.sh 
###############################################################################
#!/bin/bash
for FILE in $HOME/project_coprolite_viromes/general_bash_functions/* ; do source $FILE ; done
source /u/local/Modules/default/init/modules.sh
module load python
source $HOME/my_py/bin/activate


# define inputs variables
project_dir=$1
num_cores=$2

# define directories and file
data_dir="${project_dir}/data"
prokka_annotations="${project_dir}/prokka_annotations"
search_dir="$prokka_annotations/*bacteria"
gff_list="$data_dir/collect_bacterial_counts_tmp.txt"
csv_path="$data_dir/bacterial_gene_counts.csv"

# create a list of all files to generate counts from
ls $search_dir/*gff.gz > $gff_list

# generate counts with python script
echo "===================================================================================================="
echo "$(timestamp): collect_bacterial_counts: generating bacterial gene counts"
echo "===================================================================================================="
python3 $HOME/project_coprolite_viromes/data_wrangling/collect_raw_counts.py \
	$gff_list \
	$csv_path
rm $gff_list

# check if raw counts was created
if ls $csv_path 1> /dev/null 2>&1; then
	echo "$(timestamp): collect_bacterial_counts: bacterial gene counts csv created"
else
	echo "$(timestamp): collect_bacterial_counts: bacterial gene counts csv not found"
	exit 1
fi
