#       Aydin Karatas
#		Project Coprolite Viromes
#		create_viral_contigs.sh 
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

# annotation function uses prokka
assembly_dir="${contigs_dir}/${origin}_${sample}_assembly"
contigs_file="${assembly_dir}/${origin}_${sample}_all_contigs.fa"
annot_dir="${annotations_dir}/${origin}_${sample}_annotation_viruses"
gff_file="$annot_dir/${sample}.gff.gz"
viral_contigs_output="$assembly_dir/${origin}_${sample}_viral_contigs.fa"
echo "=================================================="
echo "$(timestamp): create_viral_contigs: identify viral contigs"
echo -e "\torigin: $origin"
echo -e "\tsample: $sample"
echo "=================================================="
identify_viral_contigs "$contigs_file" "$gff_file" "$viral_contigs_output"

gzip $contigs_file
