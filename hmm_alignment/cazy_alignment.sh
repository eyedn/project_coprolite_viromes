#!/bin/bash
###############################################################################
#       Aydin Karatas
#       Project Coprolite Viromes
#       cazy_alignment.sh
###############################################################################


code_dir="${VIROME_CODE_DIR:-$HOME/project_coprolite_viromes}"
source "$code_dir/general_bash_functions/slurm.sh"
validate_cpus "${3:-}" || exit 2


cd "${VIROME_CODE_DIR:-$HOME/project_coprolite_viromes}" || exit 1
for FILE in hmm_alignment/bash_functions/* ; do source $FILE ; done
for FILE in general_bash_functions/* ; do source $FILE ; done


# define inputs variables
origin=$1
project_dir=$2
num_cores=$3

# define sample variables
sample_record=$(select_record \
    "${project_dir}/samples/${origin}_samples.txt") || exit 2
read -r sample accession_ids <<< "$sample_record"
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
