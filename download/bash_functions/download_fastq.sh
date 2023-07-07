###############################################################################
#       Aydin Karatas
#       Project Coprolite Viromes
#       generate_fastq.sh 
###############################################################################
#!/bin/bash
source $HOME/project_coprolite_viromes/general_bash_functions/timestamp.sh
source /u/local/Modules/default/init/modules.sh
module load sra-tools


# use fasterq dump to convert the sra file to fastq file(s)
download_fastq() {
	local id=$1
	local fastq_raw_dir=$2
	local num_cores=$3

	# if conversion already happened, skip to quality control
	if ls ${fastq_raw_dir}/${id}/*.fastq 1> /dev/null 2>&1; then
		echo "$(timestamp): convert_sra_to_fastq: fastq files(s) found. skipping to quality control"
		return 0
	fi


	# convert sra to fastq format
	fasterq-dump \
		"$id" \
		--split-3 \
		-O "${fastq_raw_dir}/${id}" \
		-e "$num_cores" \
		-t "${fastq_raw_dir}/${id}_tmp"
	rm -r ${fastq_raw_dir}/${id}_tmp

	# check if fastq was created; compress fastq file(s) and delete sra file
	if ls ${fastq_raw_dir}/${id}/*.fastq 1> /dev/null 2>&1; then
		gzip ${fastq_raw_dir}/${id}/*.fastq
		echo "$(timestamp): convert_sra_to_fastq: fastq.gz created"
	else
		echo "$(timestamp): convert_sra_to_fastq: ERROR! trimmed fastq files not found"
		exit 1
	fi
}
