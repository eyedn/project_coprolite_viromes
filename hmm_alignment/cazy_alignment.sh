#!/bin/bash
###############################################################################
#       Aydin Karatas
#		Project Coprolite Viromes
#		cazy_alignment.sh 
###############################################################################
cd $HOME/project_coprolite_viromes
for FILE in hmm_alignment/bash_functions/* ; do source $FILE ; done
for FILE in general_bash_functions/* ; do source $FILE ; done


# define inputs variables
origin=$1
project_dir=$2
num_cores=$3

# define sample variables
sample=$(head -n ${SGE_TASK_ID} ${project_dir}/samples/${origin}_samples.txt | \
		tail -n 1 | cut -d ' ' -f 1)
label="bac_on_phage"

# define directories and files
alignment_dir="${project_dir}/alignment"
annotations_dir="${project_dir}/genome_annotation/${origin}_${sample}_annotation_${label}"
sample_alignment_output="${alignment_dir}/${origin}_${sample}_cazy"
orfs_file="${annotations_dir}/${sample}.faa"
db_file="${ref_db}/dbCAN-HMMdb-V12.txt" 

# align to database
echo "===================================================================================================="
echo "$(timestamp): cazy_alignment: format files $origin; $sample"
echo "===================================================================================================="
align_w_db $sample $orfs_file $db_file $sample_alignment_output $num_cores
