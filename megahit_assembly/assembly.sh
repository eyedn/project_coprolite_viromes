###############################################################################
#       Aydin Karatas
#		Project Coprolite Viromes
#		assembly.sh 
###############################################################################
#!/bin/bash
for FILE in $HOME/project_coprolite_viromes/megahit_assembly/bash_functions/* ; do source $FILE ; done
for FILE in $HOME/project_coprolite_viromes/general_bash_functions/* ; do source $FILE ; done


# define inputs variables
origin=$1
project_dir=$2
num_cores=$3
reads_dir="${project_dir}/reads"
contigs_dir="${project_dir}/contigs"
sample=$(head -n ${SGE_TASK_ID} ${project_dir}/samples/${origin}_samples.txt | \
		tail -n 1 | cut -d ' ' -f 1)
accession_ids=$(head -n ${SGE_TASK_ID} ${project_dir}/samples/${origin}_samples.txt | \
		tail -n 1 | cut -d ' ' -f 2-)

# create directory for assembly output
mkdir -p $contigs_dir
mkdir -p ${contigs_dir}/${origin}_${sample}_assembly
assembly_dir="${contigs_dir}/${origin}_${sample}_assembly"
assembly_extra_dir="${assembly_dir}_extra"
fastq_trimmed_dir="${reads_dir}/${origin}_${sample}_fastq_trimmed"

# check if assembly was already complete for this sample
if ls $assembly_dir/${origin}_${sample}_all_contigs.fa 1> /dev/null 2>&1; then
	echo "$(timestamp): assembly: final contigs file already created"
	# Check if the file is empty
	if ! [ -s "$assembly_dir/${origin}_${sample}_all_contigs.fa" ]; then
		echo "$(timestamp): assembly: contigs file is empty. deleting file and restarting assembly"
		rm $assembly_dir/${origin}_${sample}_all_contigs.fa
	else
		exit 0
	fi
elif ls ${fastq_trimmed_dir}.tar.gz 1> /dev/null 2>&1; then
	echo "$(timestamp): assembly: trimmed fastq files already gzipped"
	exit 0
fi

# check if download was already complete for this sample
if ls $fastq_trimmed_dir/*/*fq.gz 1> /dev/null 2>&1; then
	echo "$(timestamp): assembly: fastq file found"
else
	echo "$(timestamp): assembly: trimmed fastq files not found"
	rmdir $assembly_dir $assembly_extra_dir
	exit 1
fi

# assembly function uses megahit
echo "=================================================="
echo "$(timestamp): assembly: assemble all libraries associated with this sample"
echo -e "\torigin: $origin"
echo -e "\tsample: $sample"
echo "=================================================="
assemble_libraries "$sample" "$fastq_trimmed_dir" "$assembly_dir" "$assembly_extra_dir" "$num_cores"

# compress fastq trimmed files and extra assembly files
echo "$(timestamp): assembly: compressing extra files from assembly of $sample"
cd $reads_dir
tar -czvf ${origin}_${sample}_fastq_trimmed.tar.gz ${origin}_${sample}_fastq_trimmed
rm -r ${origin}_${sample}_fastq_trimmed
cd $contigs_dir
tar -czvf ${origin}_${sample}_assembly_extra.tar.gz ${origin}_${sample}_assembly_extra
rm -r ${origin}_${sample}_assembly_extra
echo "$(timestamp): assembly: assembly complete for $sample"
