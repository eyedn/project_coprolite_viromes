#       Aydin Karatas
#		Project Coprolite Viromes
#		create_viral_contigs.sh 
###############################################################################
#!/bin/bash
cd $HOME/project_coprolite_viromes
for FILE in prokka_annotations/bash_functions/* ; do source $FILE ; done
for FILE in general_bash_functions/* ; do source $FILE ; done


# define inputs variables
origin=$1
project_dir=$2
num_cores=$3

# define sample variable
sample=$(head -n ${SGE_TASK_ID} ${project_dir}/samples/${origin}_samples.txt | \
		tail -n 1 | cut -d ' ' -f 1)

# define directories and files
contigs_dir="${project_dir}/contigs"
annotations_dir="${project_dir}/prokka_annotations"
assembly_dir="${contigs_dir}/${origin}_${sample}_assembly"
contigs_file="${assembly_dir}/${origin}_${sample}_all_contigs.fa"
annot_dir="${annotations_dir}/${origin}_${sample}_annotation_viruses"
gff_file="$annot_dir/${sample}.gff.gz"
viral_contigs_output="$assembly_dir/${origin}_${sample}_viral_contigs.fa"

# check if contigs file exists
if ls $gff_file 1> /dev/null 2>&1; then
	echo "$(timestamp): create_viral_contigs: annotations file found"
else
	echo "$(timestamp): create_viral_contigs: annotations file not found"
	exit 1
fi

# check if viral contigs already indentified
if ls $viral_contigs_output 1> /dev/null 2>&1; then
	echo "$(timestamp): create_viral_contigs: viral contigs already found"
	exit 0
fi

echo "===================================================================================================="
echo "$(timestamp): create_viral_contigs: identify viral contigs: $origin; $sample"
echo "===================================================================================================="
identify_viral_contigs "$contigs_file" "$gff_file" "$viral_contigs_output"

gzip $contigs_file
