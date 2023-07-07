###############################################################################
#       Aydin Karatas
#		Project Coprolite Viromes
#		download_and_pre_process.sh 
###############################################################################
#!/bin/bash
for FILE in $HOME/project_coprolite_viromes/pre_processing/bash_functions/* ; do source $FILE ; done
source $HOME/project_coprolite_viromes/general_bash_functions/timestamp.sh


# define inputs variables
origin=$1
project_dir=$2
num_cores=$3
reads_dir="$project_dir/reads"
sample=$(head -n ${SGE_TASK_ID} ${project_dir}/samples/${origin}_samples.txt | \
		tail -n 1 | cut -d ' ' -f 1)
accession_ids=$(head -n ${SGE_TASK_ID} ${project_dir}/samples/${origin}_samples.txt | \
		tail -n 1 | cut -d ' ' -f 2-)

# create directoies for download and quality control
mkdir -p $reads_dir
mkdir -p $reads_dir/${origin}_${sample}_sra
mkdir -p $reads_dir/${origin}_${sample}_fastq_raw
mkdir -p $reads_dir/${origin}_${sample}_fastq_trimmed
sra_dir="$reads_dir/${origin}_${sample}_sra"
fastq_raw_dir="$reads_dir/${origin}_${sample}_fastq_raw"
fastq_trimmed_dir="$reads_dir/${origin}_${sample}_fastq_trimmed"

for id in $accession_ids; do
	# check if pre-processing was already complete for this id
	if ls $reads_dir/$fastq_trimmed_dir/$id/*fq.gz 1> /dev/null 2>&1; then
		echo "$(timestamp): download_and_pre_process: pre-processing for ${id} already complete"
		return 0
	fi

	# first, prefect the sra file for each accesion id
	echo "=================================================="
	echo "$(timestamp): download_and_pre_process: prefetching sra file"
	echo -e "\torigin: $origin"
	echo -e "\tsample: $sample"
	echo -e "\tid: $id"
	echo "=================================================="
	# uses prefetch from sra tool kit
	download_sra "$id" "$sra_dir"

	# second, convert sra files to fastq files
	echo "=================================================="
	echo "$(timestamp): download_and_pre_process: converting sra file to fastq files"
	echo -e "\torigin: $origin"
	echo -e "\tsample: $sample"
	echo -e "\tid: $id"
	echo "=================================================="
	# uses fasterq-dump from sra tool kit
	generate_fastq "$id" "$sra_dir" "$fastq_raw_dir" "$num_cores"

	# quality control fastq files by removing adapters and low quality reads
	echo "=================================================="
	echo "$(timestamp): download_and_pre_process: quality control fastq files"
	echo -e "\torigin: $origin"
	echo -e "\tsample: $sample"
	echo -e "\tid: $id"
	echo "=================================================="
	# quality control uses trim-galore to remove adapters and low quality sequences
	quality_control "$id" "$fastq_raw_dir" "$fastq_trimmed_dir" "$num_cores"
	echo "$(timestamp): download_and_pre_process: pre-processing complete for $id"
done

rm -r $sra_dir
rm -r $fastq_raw_dir
echo "$(timestamp): download_and_pre_process: pre-processing complete for $sample"

