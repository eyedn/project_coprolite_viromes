###############################################################################
#       Aydin Karatas
#		Project Coprolite Viromes
#		get_indiv_viral_prop.sh 
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

# define sample variable
sample=$(head -n ${SGE_TASK_ID} ${project_dir}/samples/${origin}_samples.txt | \
		tail -n 1 | cut -d ' ' -f 1)

# define directories and file
contigs_dir="${project_dir}/contigs"
prokka_annotations="${project_dir}/genome_annotation"
data_dir="$project_dir/data/indiv_viral_prop"
fa_file="$contigs_dir/${origin}_${sample}_assembly/${origin}_${sample}_viral_contigs.fa.gz"
gff_file="$prokka_annotations/${origin}_${sample}_annotation_viruses/${sample}.gff.gz"
csv_path="$data_dir/${origin}_${sample}_viral_prop.csv"

mkdir -p $data_dir

# check if assembly was already complete for this sample
if ls $csv_path 1> /dev/null 2>&1; then
	echo "$(timestamp): get_indiv_viral_prop: final contigs file already created"
	return 0
fi

# check if download was already complete for this sample
if ls $fa_file 1> /dev/null 2>&1; then
	echo "$(timestamp): get_indiv_viral_prop: fa file found"
else
	echo "$(timestamp): get_indiv_viral_prop: fa file not found"
	exit 1
fi
if ls $gff_file 1> /dev/null 2>&1; then
	echo "$(timestamp): get_indiv_viral_prop: gff file found"
else
	echo "$(timestamp): get_indiv_viral_prop: gff file not found"
	exit 1
fi

# generate counts with python script
echo "===================================================================================================="
echo "$(timestamp): get_indiv_viral_prop: generating viral prop. counts"
echo "===================================================================================================="
python3 data_wrangling/get_indiv_viral_prop.py \
	$fa_file \
	$gff_file \
	$csv_path

# check if raw counts was created
if ls $csv_path 1> /dev/null 2>&1; then
	echo "$(timestamp): get_indiv_viral_prop: viral prop csv created"
else
	echo "$(timestamp): get_indiv_viral_prop: viral prop csv not found"
	exit 1
fi
