###############################################################################
#       Aydin Karatas
#       Project Coprolite Viromes
#       quality_control.sh 
###############################################################################


# use trim galore to remove adapters and low quality reads
quality_control() {
	local id=$1
	local fastq_raw_dir=$2
	local fastq_trimmed_dir=$3
	local num_cores=$4

	# check if trimmed file(s) already exists, return from pre-processing
	if ls ${fastq_trimmed_dir}/${id}/*.txt 1> /dev/null 2>&1; then
	echo "$(timestamp): quality_check_fastq: trimmed fastq files found. skipping to final data compression steps"
		return 0
	fi

	# establish number of cores to use
	if [ "$num_cores" -gt "$trim_galore_cores" ]; then
		cores_to_use="$trim_galore_cores";
	else
		cores_to_use="$num_cores"
	fi

	# trim adaptors and low quality positions; remove low quality reads
	# run quality check based on if sample is single-end or paired-end data
	mkdir -p $fastq_trimmed_dir
	if [ -f "${fastq_raw_dir}/${id}/${id}_1.fastq.gz" ] && \
	[ -f "${fastq_raw_dir}/${id}/${id}_2.fastq.gz" ]; then
		$trim_galore \
			--paired \
			-o ${fastq_trimmed_dir}/${id} \
			--gzip \
			-j $cores_to_use \
			${fastq_raw_dir}/${id}/${id}_1.fastq.gz \
			${fastq_raw_dir}/${id}/${id}_2.fastq.gz
	elif [ -f "${fastq_raw_dir}/${id}/${id}.sralite_1.fastq.gz" ] && \
	[ -f "${fastq_raw_dir}/${id}/${id}.sralite_2.fastq.gz" ]; then
		$trim_galore \
			--paired \
			-o ${fastq_trimmed_dir}/${id} \
			--gzip \
			-j $cores_to_use \
			${fastq_raw_dir}/${id}/${id}.sralite_1.fastq.gz \
			${fastq_raw_dir}/${id}/${id}.sralite_2.fastq.gz
	elif [ -f "${fastq_raw_dir}/${id}/${id}.fastq.gz" ]; then
		$trim_galore \
			-o ${fastq_trimmed_dir}/${id} \
			--gzip \
			-j $cores_to_use \
			${fastq_raw_dir}/${id}/${id}.fastq.gz
	elif [ -f "${fastq_raw_dir}/${id}/${id}.sralite.fastq.gz" ]; then
		$trim_galore \
			-o ${fastq_trimmed_dir}/${id} \
			--gzip \
			-j $cores_to_use \
			${fastq_raw_dir}/${id}/${id}.sralite.fastq.gz
	fi

	# check if trimmd file(s) created
	if ls ${fastq_trimmed_dir}/${id}/*.fq.gz 1> /dev/null 2>&1; then
		echo "$(timestamp): quality_check_fastq: trimmed fastq files created"
		rm -r ${fastq_raw_dir}/${id}
	else
		echo "$(timestamp): quality_check_fastq: ERROR! trimmed fastq files not found"
		exit 1
	fi
}
