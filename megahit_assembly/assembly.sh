#!/bin/bash
###############################################################################
#       Aydin Karatas
#		Project Coprolite Viromes
#		assembly.sh 
###############################################################################
cd $HOME/project_coprolite_viromes
for FILE in megahit_assembly/bash_functions/* ; do source $FILE ; done
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

# define directories
reads_dir="${project_dir}/reads"
contigs_dir="${project_dir}/contigs"
assembly_dir="${contigs_dir}/${origin}_${sample}_assembly"
assembly_extra_dir="${assembly_dir}_extra"
fastq_clean_dir="$reads_dir/${origin}_${sample}_fastq_clean"

# check if assembly was already complete for this sample
if ls $assembly_dir/${origin}_${sample}_all_contigs.fa* 1> /dev/null 2>&1; then
	echo "$(timestamp): assembly: final contigs file already created"
	return 0
fi

# check if download was already complete for this sample
if ls $fastq_clean_dir/*/*fastq.gz 1> /dev/null 2>&1; then
	echo "$(timestamp): assembly: fastq file(s) found"
else
	echo "$(timestamp): assembly: ERROR! clean fastq files not found"
	exit 1
fi

# assembly function uses megahit
echo "===================================================================================================="
echo "$(timestamp): assembly: assemble all libraries associated with this sample: $origin; $sample"
echo "===================================================================================================="
assemble_libraries "$sample" "$fastq_clean_dir" "$assembly_dir" "$assembly_extra_dir" "$num_cores"

rm $fastq_clean_dir/*/*.gz
rmdir $fastq_clean_dir/*
rm -r $assembly_extra_dir
echo "$(timestamp): assembly: assembly complete for $sample"
