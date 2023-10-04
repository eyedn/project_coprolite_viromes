#!/bin/bash
###############################################################################
#       Aydin Karatas
#       Project Coprolite Viromes
#       remove_human_reads.sh 
###############################################################################


# use kneaddata to remove human reads
remove_human_reads() {
	local id=$1
	local fastq_trimmed_dir=$2
	local fastq_clean_dir=$3
	local num_cores=$4

	# check if clean file(s) already exists, return from pre-processing
	if ls ${fastq_clean_dir}/${id}/*R*fastq.gz 1> /dev/null 2>&1; then
		echo "$(timestamp): remove_human_reads: clean fastq files found. skipping to final data compression steps"
		return 0
	fi

	# remove host sequences based on if data is paired or unpaired
	mkdir -p $fastq_clean_dir
	cd ${fastq_trimmed_dir}/${id}
	if [ -f "${fastq_trimmed_dir}/${id}/${id}_val_1.fq.gz" ] && \
	[ -f "${fastq_trimmed_dir}/${id}/${id}_val_2.fq.gz" ]; then
		$bowtie2 \
			-p $num_cores \
			-x $hum_genome_ref \
			-1 ${fastq_trimmed_dir}/${id}/${id}_val_1.fq.gz \
			-2 ${fastq_trimmed_dir}/${id}/${id}_val_2.fq.gz \
			--un-conc-gz \
			${id}_SAMPLE_host_removed \
			> ${id}_SAMPLE_mapped_and_unmapped.sam

		# check if bowtie2 ran correctly
		if [ $? -ne 0 ]; then
			echo "$(timestamp): Error running bowtie2 for sample $id"
			exit 1
		fi

		echo "$(timestamp): bowtie2 results"
		ls

		mv ${id}_SAMPLE_host_removed.1 \
			${fastq_clean_dir}/${id}/${id}_R1.fastq.gz
		mv ${id}_SAMPLE_host_removed.2 \
			${fastq_clean_dir}/${id}/${id}_R2.fastq.gz
		rm ${id}_SAMPLE_mapped_and_unmapped.sam
	elif [ -f "${fastq_trimmed_dir}/${id}/${id}_trimmed.fq.gz" ]; then
		$bowtie2 \
			-p $num_cores \
			-x $hum_genome_ref \
			-U ${fastq_trimmed_dir}/${id}/${id}_trimmed.fq.gz \
			--un-gz \
			${id}_SAMPLE_host_removed \
			> ${id}_SAMPLE_mapped_and_unmapped.sam

		# check if bowtie2 ran correctly
		if [ $? -ne 0 ]; then
			echo "$(timestamp): Error running bowtie2 for sample $id"
			exit 1
		fi

		echo "$(timestamp): bowtie2 results"
		ls

		mv ${id}_SAMPLE_host_removed \
			${fastq_clean_dir}/${id}/${id}_RU.fastq.gz
		rm ${id}_SAMPLE_mapped_and_unmapped.sam
	else
		echo "$(timestamp): remove_human_reads: ERROR! trimmed fastq files not found"
		exit 1
	fi

	# check if cleaned file(s) created
	if ls ${fastq_clean_dir}/${id}/*R*fastq.gz 1> /dev/null 2>&1; then
		echo "$(timestamp): remove_human_reads: clean fastq files created"
	else
		echo "$(timestamp): remove_human_reads: ERROR! clean fastq files not found"
		exit 1
	fi
}
