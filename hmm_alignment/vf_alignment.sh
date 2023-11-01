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
incE="1e-3"

# define directories and files
alignment_dir="${project_dir}/alignment"
sample_alignment="${alignment_dir}/${origin}_${sample}_alignment"
sample_alignment_output="${alignment_dir}/${origin}_${sample}_vf"
hmm_file="${sample_alignment}/${origin}_${sample}.hmm"
db_file="${ref_db}/VFDB_setB_pro.hmm" 

# align to database
echo "===================================================================================================="
echo "$(timestamp): vf_alignment: format files $origin; $sample"
echo "===================================================================================================="
align_w_db $sample $hmm_file $db_file $sample_alignment_output $num_cores $incE
