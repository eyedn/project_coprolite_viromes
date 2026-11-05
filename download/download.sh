#!/bin/bash
###############################################################################
#       Aydin Karatas
#       Project Coprolite Viromes
#       download.sh
###############################################################################


code_dir="${VIROME_CODE_DIR:-$HOME/project_coprolite_viromes}"
source "$code_dir/general_bash_functions/slurm.sh"
validate_cpus "${3:-}" || exit 2


cd "${VIROME_CODE_DIR:-$HOME/project_coprolite_viromes}" || exit 1
for FILE in download/bash_functions/* ; do source $FILE ; done
for FILE in general_bash_functions/* ; do source $FILE ; done
activate_environment qc || exit 1


# define inputs variables
origin=$1
project_dir=$2
num_cores=$3

# define sample variables
sample_record=$(select_record \
    "${project_dir}/samples/${origin}_samples.txt") || exit 2
read -r sample accession_ids <<< "$sample_record"

# define directires
reads_dir="$project_dir/reads"
sra_dir="$reads_dir/${origin}_${sample}_sra"
fastq_raw_dir="$reads_dir/${origin}_${sample}_fastq_raw"
fastq_trimmed_dir="$reads_dir/${origin}_${sample}_fastq_trimmed"
fastq_clean_dir="$reads_dir/${origin}_${sample}_fastq_clean"
data_dir="$project_dir/data/read_stats"

# check if download process already was complete for this sample
if ls ${reads_dir}/${origin}_${sample}_DONE.txt 1> /dev/null 2>&1; then
	echo "$(timestamp): download: ${reads_dir}/${origin}_${sample}_DONE.txt found."
	return 0
fi

for id in $accession_ids; do
	fastq_stats="$data_dir/${origin}_${sample}_${id}_read_stats.txt"
	fastq_stats_done="$data_dir/${origin}_${sample}_${id}_read_stats_DONE.txt"
	mkdir -p $data_dir
	echo "${origin}_${sample}_${id}" > $fastq_stats

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
	echo "===================================================================================================="
	echo "$(timestamp): download: quality control fastq files: $origin; $sample; $id"
	echo "===================================================================================================="
	# quality control uses trim-galore to remove adapters and low quality sequences
	quality_control "$id" "$fastq_raw_dir" "$fastq_trimmed_dir" "$fastq_stats" "$num_cores"

	# remove human reads from fastq files
	echo "===================================================================================================="
	echo "$(timestamp): download: remove human dna from trimmed reads: $origin; $sample; $id"
	echo "===================================================================================================="
	# host removal uses bowtie2 
	remove_human_reads "$id" "$fastq_trimmed_dir" "$fastq_clean_dir" "$fastq_stats" "$num_cores"

	echo "$(timestamp): download: pre-processing complete for $id"
	mv $fastq_stats $fastq_stats_done
done

touch ${reads_dir}/${origin}_${sample}_DONE.txt
echo "$(timestamp): download_and_pre_process: pre-processing complete for $sample"
