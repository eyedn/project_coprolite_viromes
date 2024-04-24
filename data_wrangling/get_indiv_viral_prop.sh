#!/bin/bash
###############################################################################
#       Aydin Karatas
#		Project Coprolite Viromes
#		get_indiv_viral_prop.sh 
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

# define sample variable
sample=$(head -n ${SGE_TASK_ID} ${project_dir}/samples/${origin}_samples.txt | \
		tail -n 1 | cut -d ' ' -f 1)

# define directories and file
contigs_dir="${project_dir}/contigs"
prokka_annotations="${project_dir}/genome_annotation"
data_dir_all="$project_dir/data/indiv_viral_prop_all"
data_dir_no_hypo="$project_dir/data/indiv_viral_prop_no_hypo"
fa_file="$contigs_dir/${origin}_${sample}_assembly/${origin}_${sample}_all_contigs.fa.gz"
gff_file="$prokka_annotations/${origin}_${sample}_annotation_viruses/${sample}.gff.gz"
csv_path_all="$data_dir_all/${origin}_${sample}_viral_prop_all.csv"
csv_path_no_hypo="$data_dir_no_hypo/${origin}_${sample}_viral_prop_no_hypo.csv"

# check if download was already complete for this sample
if ls $fa_file 1> /dev/null 2>&1; then
	echo "$(timestamp): get_indiv_viral_prop: fa file found"
else
	echo "$(timestamp): get_indiv_viral_prop: ERROR! fa file not found"
	exit 1
fi
if ls $gff_file 1> /dev/null 2>&1; then
	echo "$(timestamp): get_indiv_viral_prop: gff file found"
else
	echo "$(timestamp): get_indiv_viral_prop: ERROR! gff file not found"
	exit 1
fi

# generate counts with python script
echo "===================================================================================================="
echo "$(timestamp): get_indiv_viral_prop: generating viral prop. counts"
echo "===================================================================================================="
mkdir -p $data_dir_all $data_dir_no_hypo
python3 data_wrangling/get_indiv_viral_prop.py \
	$fa_file \
	$gff_file \
	$csv_path_all \
	$csv_path_no_hypo

# check if viral prop csv's created
if ls $csv_path_all 1> /dev/null 2>&1; then
	echo "$(timestamp): get_indiv_viral_prop: viral prop all csv created"
else
	echo "$(timestamp): get_indiv_viral_prop: ERROR! viral prop all csv not found"
	exit 1
fi

if ls $csv_path_no_hypo 1> /dev/null 2>&1; then
	echo "$(timestamp): get_indiv_viral_prop: viral prop no hypo csv created"
else
	echo "$(timestamp): get_indiv_viral_prop: ERROR! viral prop no hypo csv not found"
	exit 1
fi
