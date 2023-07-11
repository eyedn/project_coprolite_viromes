###############################################################################
#       Aydin Karatas
#		Project Coprolite Viromes
#		viral_annotation.sh 
###############################################################################
#!/bin/bash
cd $HOME/project_coprolite_viromes
for FILE in prokka_annotations/bash_functions/* ; do source $FILE ; done
for FILE in general_bash_functions/* ; do source $FILE ; done


# define inputs variables
origin=$1
project_dir=$2
num_cores=$3

# define sample variables
sample=$(head -n ${SGE_TASK_ID} ${project_dir}/samples/${origin}_samples.txt | \
		tail -n 1 | cut -d ' ' -f 1)
type="Viruses"
label="viruses"

# define directories and files
contigs_dir="${project_dir}/contigs"
annotations_dir="${project_dir}/prokka_annotations"
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
	return 0
fi

# annotation function uses prokka
echo "===================================================================================================="
echo "$(timestamp): viral annotation: $origin; $sample"
echo "===================================================================================================="
annotate_contigs "$sample" "$contigs_file" "$custom_db" "$annot_dir" \
	"$type" "$label" "$num_cores"

# compress annotation files
gzip $annot_dir/*
