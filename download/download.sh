###############################################################################
#       Aydin Karatas
#		Project Coprolite Viromes
#		download.sh 
###############################################################################
#!/bin/bash
cd $HOME/project_coprolite_viromes
for FILE in download/bash_functions/* ; do source $FILE ; done
for FILE in general_bash_functions/* ; do source $FILE ; done


# define inputs variables
origin=$1
project_dir=$2
num_cores=$3

# define sample variables
sample=$(head -n ${SGE_TASK_ID} ${project_dir}/samples/${origin}_samples.txt | \
		tail -n 1 | cut -d ' ' -f 1)
accession_ids=$(head -n ${SGE_TASK_ID} ${project_dir}/samples/${origin}_samples.txt | \
		tail -n 1 | cut -d ' ' -f 2-)

# define directires
reads_dir="$project_dir/reads"
sra_dir="$reads_dir/${origin}_${sample}_sra"
fastq_raw_dir="$reads_dir/${origin}_${sample}_fastq_raw"
fastq_trimmed_dir="$reads_dir/${origin}_${sample}_fastq_trimmed"

for id in $accession_ids; do
	# check if download was already complete for this id
	if ls $fastq_trimmed_dir/$id/*.txt 1> /dev/null 2>&1; then
		echo "$(timestamp): download: pre-processing for ${id} already complete"
		continue
	fi

	# download sra file for each accesion id
	echo "===================================================================================================="
	echo "$(timestamp): download: prefetching sra file: $origin; $sample; $id"
	echo "===================================================================================================="
	# uses prefetch from sra tool kit
	download_sra "$id" "$sra_dir"

	# convert sra file to fastq file(s)
	echo "===================================================================================================="
	echo "$(timestamp): download: converting sra file to fastq files: $origin; $sample; $id"
	echo "===================================================================================================="
	# uses fasterq-dump from sra tool kit
	generate_fastq "$id" "$sra_dir" "$fastq_raw_dir" "$num_cores"

	# quality control fastq files by removing adapters and low quality reads
	echo "=================================================="
	echo "$(timestamp): download: quality control fastq files: $origin; $sample; $id"
	echo "=================================================="
	# quality control uses trim-galore to remove adapters and low quality sequences
	quality_control "$id" "$fastq_raw_dir" "$fastq_trimmed_dir" "$num_cores"
	echo "$(timestamp): download: pre-processing complete for $id"
done

# deleted unnecessary directories
if [ -d "$sra_dir" ]; then
	rm -r "$sra_dir"
fi

if [ -d "$fastq_raw_dir" ]; then
	rm -r "$fastq_raw_dir"
fi

echo "$(timestamp): download_and_pre_process: pre-processing complete for $sample"
