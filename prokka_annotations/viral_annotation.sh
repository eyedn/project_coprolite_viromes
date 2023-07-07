###############################################################################
#       Aydin Karatas
#		Project Coprolite Viromes
#		viral_annotation.sh 
###############################################################################
#!/bin/bash
for FILE in $HOME/project_coprolite_viromes/prokka_annotations/bash_functions/* ; do source $FILE ; done
source $HOME/project_coprolite_viromes/general_bash_functions/timestamp.sh


# define inputs variables
origin=$1
project_dir=$2
num_cores=$3
contigs_dir="${project_dir}/contigs"
annotations_dir="${project_dir}/prokka_annotations"
sample=$(head -n ${SGE_TASK_ID} ${project_dir}/samples/${origin}_samples.txt | \
		tail -n 1 | cut -d ' ' -f 1)

# define variables for annotation
type="Viruses"
label="viruses"
mkdir -p $annotations_dir
assembly_dir="${contigs_dir}/${origin}_${sample}_assembly"
contigs_file="${assembly_dir}/${origin}_${sample}_all_contigs.fa"
annot_dir="${annotations_dir}/${origin}_${sample}_annotation_${label}"
custom_db="no_data"

# check if contigs file exists
if ls $contigs_file 1> /dev/null 2>&1; then
	echo "$(timestamp): viral_annotation: contigs file found"
else
	echo "$(timestamp): viral_annotation: contigs file not found"
	rmdir $annot_dir
	exit 1
fi

# check if annotations already completed
if ls $annot_dir 1> /dev/null 2>&1; then
	echo "$(timestamp): viral_annotation: annotations already completed"
	exit 0
fi

# annotation function uses prokka
echo "=================================================="
echo "$(timestamp): viral annotation"
echo -e "\torigin: $origin"
echo -e "\tsample: $sample"
echo "=================================================="
annotate_contigs "$sample" "$contigs_file" "$custom_db" "$annot_dir" \
	"$type" "$label" "$num_cores"

# compress annotation files
gzip $annot_dir/*
