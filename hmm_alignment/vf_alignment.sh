###############################################################################
#       Aydin Karatas
#		Project Coprolite Viromes
#		vf_alignment.sh 
###############################################################################
#!/bin/bash
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
sample_alignment="${alignment_dir}/${origin}_${sample}_alignment"
references_dir="${project_dir}/references"
hmm_file="${sample_alignment}/${origin}_${sample}.hmm"
db_file="${references_dir}/VFDB_setB_pro.fas" 

# align to database
echo "===================================================================================================="
echo "$(timestamp): vf_alignment: format files $origin; $sample"
echo "===================================================================================================="
align_w_db $sample $hmm_file $db_file $sample_alignment $num_cores