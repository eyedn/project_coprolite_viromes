#!/bin/bash
###############################################################################
#       Aydin Karatas
#		Project Coprolite Viromes
#		bacterial_annot_all.sh 
###############################################################################
cd $HOME/project_coprolite_viromes
for FILE in prokka_annotations/bash_functions/* ; do source $FILE ; done
for FILE in general_bash_functions/* ; do source $FILE ; done
source /u/local/Modules/default/init/modules.sh
module load anaconda3
conda activate prokka


# define inputs variables
origin=$1
project_dir=$2
num_cores=$3

# define sample variables
sample=$(head -n ${SGE_TASK_ID} ${project_dir}/samples/${origin}_samples.txt | \
		tail -n 1 | cut -d ' ' -f 1)
type="Bacteria"
label="all"

# define directories and files
contigs_dir="${project_dir}/contigs"
annotations_dir="${project_dir}/genome_annotation"
assembly_dir="${contigs_dir}/${origin}_${sample}_assembly"
contigs_file="${assembly_dir}/${origin}_${sample}_all_contigs.fa"
sample_annot_dir="${annotations_dir}/${origin}_${sample}_annotation_${label}"
custom_db="no_data"

# check if contigs file exists
if ls ${contigs_file}* 1> /dev/null 2>&1; then
	echo "$(timestamp): bacterial_annot_prokka: contigs file found"
else
	echo "$(timestamp): bacterial_annot_prokka: contigs file not found"
	rmdir $annot_dir
	exit 1
fi

# check if annotations already completed
if ls ${sample_annot_dir}/*gff.gz  1> /dev/null 2>&1; then
	echo "$(timestamp): bacterial_annot_prokka: annotations already completed"
	return 0
else
	rmdir $annot_dir
fi

# annotation function uses prokka
echo "===================================================================================================="
echo "$(timestamp): bacterial_annot_prokka: $origin; $sample"
echo "===================================================================================================="
annotate_contigs "$sample" "$contigs_file" "$custom_db" "$sample_annot_dir" \
	"$type" "$label" "$num_cores"

# compress annotation files
gzip $sample_annot_dir/*
