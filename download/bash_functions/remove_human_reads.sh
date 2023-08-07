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
		echo "$(timestamp): quality_check_fastq: clean fastq files found. skipping to final data compression steps"
		return 0
	fi

	# remove host sequences based on if data is paired or unpaired
	mkdir -p $fastq_clean_dir
	if [ -f "${fastq_trimmed_dir}/${id}/${id}_val_1.fq.gz" ] && \
	[ -f "${fastq_trimmed_dir}/${id}/${id}_val_2.fq.gz" ]; then
		kneaddata \
			--input1 ${fastq_trimmed_dir}/${id}/${id}_val_1.fq.gz \
			--input2 ${fastq_trimmed_dir}/${id}/${id}_val_2.fq.gz \
			--reference-db $ref_db \
			--output ${fastq_clean_dir}/${id} \
			--trf $trf_dir \
			--sequencer-source none \
			--threads $num_cores

		mv ${fastq_clean_dir}/${id}/${id}_val_1_kneaddata_paired_1.fastq \
			> ${fastq_clean_dir}/${id}/${id}_R1.fastq
		mv ${fastq_clean_dir}/${id}/${id}_val_1_kneaddata_paired_2.fastq \
			> ${fastq_clean_dir}/${id}/${id}_R2.fastq
		mv ${fastq_clean_dir}/${id}/${id}_val_1_kneaddata.log \
			> ${fastq_clean_dir}/${id}/${id}.log 
	elif [ -f "${fastq_trimmed_dir}/${id}/${id}_trimmed.fq.gz" ]; then
		kneaddata \
			--unpaired ${fastq_trimmed_dir}/${id}/${id}_trimmed.fq.gz \
			--reference-db $ref_db \
			--output ${fastq_clean_dir}/${id} \
			--trf $trf_dir \
			--sequencer-source none \
			--threads $num_cores

		mv ${fastq_clean_dir}/${id}/${id}_trimmed_kneaddata.fastq \
			> ${fastq_clean_dir}/${id}/${id}_RU.fastq
		mv ${fastq_clean_dir}/${id}/${id}_trimmed_kneaddata.log \
			> ${fastq_clean_dir}/${id}/${id}.log 
	else
		echo "$(timestamp): quality_check_fastq: ERROR! trimmed fastq files not found"
		exit 1
	fi

	# check if cleaned file(s) created
	if ls ${fastq_clean_dir}/${id}/*R*fastq 1> /dev/null 2>&1; then
		echo "$(timestamp): quality_check_fastq: clean fastq files created"
		rm ${fastq_trimmed_dir}/${id}/*fq.gz
		rm ${fastq_clean_dir}/${id}/*kneaddata*
		gzip ${fastq_clean_dir}/${id}/*R*fastq
	else
		echo "$(timestamp): quality_check_fastq: ERROR! clean fastq files not found"
		exit 1
	fi
}
