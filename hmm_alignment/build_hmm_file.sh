###############################################################################
#       Aydin Karatas
#		Project Coprolite Viromes
#		build_hmm_file.sh 
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
annotations_dir="${project_dir}/genome_annotation"
annot_dir="${annotations_dir}/${origin}_${sample}_annotation_${label}"
aa_file="${annot_dir}/${sample}.faa"
sto_file="${sample_alignment}/${origin}_${sample}.sto"
hmm_file="${sample_alignment}/${origin}_${sample}.hmm"

# convert faa file to sto file
echo "===================================================================================================="
echo "$(timestamp): build_hmm_file: format files $origin; $sample"
echo "===================================================================================================="
get_sto_file $aa_file $sto_file

# use sto file to create a hmm file (multiple sequence alignment)
echo "===================================================================================================="
echo "$(timestamp): build_hmm_file: build hmm file $origin; $sample"
echo "===================================================================================================="
get_hmm_file $sto_file $hmm_file
