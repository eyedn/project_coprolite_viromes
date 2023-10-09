#!/bin/bash
###############################################################################
#       Aydin Karatas
#       Project Coprolite Viromes
#       generate_fastq.sh 
###############################################################################


# use fasterq dump to download fastq files
generate_fastq() {
	local id=$1
	local sra_dir=$2
	local fastq_raw_dir=$3
	local num_cores=$4

	# check if sra to fastq conversion was already completed
	if ls ${fastq_raw_dir}/${id}_DONE.txt 1> /dev/null 2>&1; then
		echo "$(timestamp): convert_sra_to_fastq: ${fastq_raw_dir}/${id}_DONE.txt found"
		return 0
	fi

	# identify the sra file to use
	if [ -f "${sra_dir}/${id}/${id}.sra" ]; then
		sra_file="${sra_dir}/${id}/${id}.sra"
	elif [ -f "${sra_dir}/${id}/${id}.sralite" ]; then
		sra_file="${sra_dir}/${id}/${id}.sralite"
	else
		echo "$(timestamp): convert_sra_to_fastq: ERROR! sra* file not detected"
		exit 1
	fi

	# establish number of cores to use
	if [ "$num_cores" -gt "$fasterq_dump_cores" ]; then
		cores_to_use="$fasterq_dump_cores";
	else
		cores_to_use="$num_cores"
	fi

	# convert sra to fastq format
	mkdir -p $fastq_raw_dir
	$fasterq_dump \
		"$sra_file" \
		--split-3 \
		-O "${fastq_raw_dir}/${id}" \
		-e "$cores_to_use" \
		-t "${fastq_raw_dir}/${id}_tmp"
	rm -r ${fastq_raw_dir}/${id}_tmp

	# check if fastq was created
	if ls ${fastq_raw_dir}/${id}/*.fastq 1> /dev/null 2>&1; then
		gzip ${fastq_raw_dir}/${id}/*.fastq
		echo "$(timestamp): convert_sra_to_fastq: fastq.gz created"
	else
		echo "$(timestamp): convert_sra_to_fastq: ERROR! trimmed fastq files not found"
		exit 1
	fi

	# create file to indicate completion of sra to fastq conversion
	touch ${fastq_raw_dir}/${id}_DONE.txt
	rm -r ${sra_dir}/${id}
}
