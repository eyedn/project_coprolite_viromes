#!/bin/bash
###############################################################################
#       Aydin Karatas
#       Project Coprolite Viromes
#       create_viral_phage_contigs.sh
###############################################################################


code_dir="${VIROME_CODE_DIR:-$HOME/project_coprolite_viromes}"
source "$code_dir/general_bash_functions/slurm.sh"
validate_cpus "${3:-}" || exit 2


cd "${VIROME_CODE_DIR:-$HOME/project_coprolite_viromes}" || exit 1
for FILE in prokka_annotations/bash_functions/* ; do source $FILE ; done
for FILE in general_bash_functions/* ; do source $FILE ; done
activate_environment python || exit 1


# define inputs variables
origin=$1
project_dir=$2
num_cores=$3

# define sample variable
sample_record=$(select_record \
    "${project_dir}/samples/${origin}_samples.txt") || exit 2
read -r sample accession_ids <<< "$sample_record"

# define directories and files
contigs_dir="${project_dir}/contigs"
annotations_dir="${project_dir}/genome_annotation"
assembly_dir="${contigs_dir}/${origin}_${sample}_assembly"
all_contigs="${assembly_dir}/${origin}_${sample}_all_contigs.fa"
phage_contigs="${project_dir}/phage_predictions/${origin}_${sample}_prediction/predicted_phage.fa"
annot_dir="${annotations_dir}/${origin}_${sample}_annotation_viruses"
gff_file="$annot_dir/${sample}.gff.gz"
viral_contigs_output="$assembly_dir/${origin}_${sample}_viral_phage_contigs.fa"

# check if contigs file exists
if ls $gff_file 1> /dev/null 2>&1; then
	echo "$(timestamp): create_viral_phage_contigs: annotations file found"
else
	echo "$(timestamp): create_viral_phage_contigs: annotations file not found"
	exit 1
fi

# check if viral contigs already indentified
if ls ${viral_contigs_output}* 1> /dev/null 2>&1; then
	echo "$(timestamp): create_viral_phage_contigs: viral contigs already found"
	return 0
fi

echo "===================================================================================================="
echo "$(timestamp): create_viral_phage_contigs: identify viral contigs: $origin; $sample"
echo "===================================================================================================="
identify_viral_phage_contigs "$all_contigs" "$phage_contigs" "$gff_file" "$viral_contigs_output"

gzip $viral_contigs_output
