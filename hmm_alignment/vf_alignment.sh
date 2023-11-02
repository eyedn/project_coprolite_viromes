#!/bin/bash
###############################################################################
#       Aydin Karatas
#		Project Coprolite Viromes
#		vf_alignment.sh 
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
label="phage"

# define directories and files
alignment_dir="${project_dir}/alignment"
annotations_dir="${project_dir}/genome_annotation/${origin}_${sample}_annotation_${label}"
sample_alignment_output="${alignment_dir}/${origin}_${sample}_vf"
orfs_file="${annotations_dir}/${sample}.faa"
db_file="${ref_db}/VFDB_db_profiles.txt"

# align to database
echo "===================================================================================================="
echo "$(timestamp): vf_alignment: format files $origin; $sample"
echo "===================================================================================================="
align_w_db $sample $orfs_file $db_file $sample_alignment_output $num_cores
