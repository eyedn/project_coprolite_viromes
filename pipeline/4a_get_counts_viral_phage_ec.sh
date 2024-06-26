#!/bin/bash
##############################################################################
#       Aydin Karatas
#		Project Coprolite Viromes
#		4a_get_counts_viral_phage_ec.sh 
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
search_dir="$prokka_annotations/*bac_on_virus_and_phage"
viral_vs_phage_prop_dir="$data_dir/indiv_viral_vs_phage_prop"
gff_list="$data_dir/vir_phage_ec_counts_tmp.txt"
ec_csv_path="$data_dir/vir_phage_ec_counts.csv"
viral_vs_phage_csv_path="$data_dir/viral_vs_phage_prop_all.csv"

# generate counts with python script
echo "===================================================================================================="
echo "$(timestamp): 4a_get_counts_viral_phage_ec: generating bacterial gene counts"
echo "===================================================================================================="
# create a list of all files to generate counts from
mkdir -p $data_dir
ls $search_dir/*gff.gz > $gff_list
echo "$(timestamp): 4a_get_counts_viral_phage_ec: generated file of all file paths needed"
echo "$(timestamp): 4a_get_counts_viral_phage_ec: using the following files:"
cat $gff_list

# generate csv file of all hits to genes with known ec for all samples
python3 data_wrangling/collect_ec_counts.py \
	$gff_list \
	$ec_csv_path
rm $gff_list

# generate csv file that combines viral contig vs phage contig counts for all samples
python3 data_wrangling/combine_viral_vs_phage_prop.py \
	$viral_vs_phage_prop_dir \
	$viral_vs_phage_csv_path

# check if raw counts was created
if ls $ec_csv_path 1> /dev/null 2>&1; then
	echo "$(timestamp): 4a_get_counts_viral_phage_ec: bacterial gene counts csv created"
else
	echo "$(timestamp): 4a_get_counts_viral_phage_ec: ERROR! bacterial gene counts csv not found"
	exit 1
fi
