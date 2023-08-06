###############################################################################
#       Aydin Karatas
#       Project Coprolite Viromes
#       remove_human_reads.sh 
###############################################################################


# use bowtie and samtools to remove human sample
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
	mkdir -p ${fastq_clean_dir}/${id}
	if [ -f "${fastq_trimmed_dir}/${id}/${id}_val_1.fq.gz" ] && \
	[ -f "${fastq_trimmed_dir}/${id}/${id}_val_2.fq.gz" ]; then
		# TODO: test pipeline with paired data
		$bowtie2 -p ${num_cores} -x ${hum_genome_ref} \
			-1 ${fastq_trimmed_dir}/${id}/${id}_val_1.fq.gz \
			-2 ${fastq_trimmed_dir}/${id}/${id}_val_2.fq.gz \
			-S ${fastq_clean_dir}/${id}/${id}_mapped_and_unmapped_tmp.sam

		$samtools view -bS ${fastq_clean_dir}/${id}/${id}_mapped_and_unmapped_tmp.sam \
			> ${fastq_clean_dir}/${id}/${id}_mapped_and_unmapped_tmp.bam

		$samtools view -b -f 12 -F 256 \
			${fastq_clean_dir}/${id}/${id}_mapped_and_unmapped_tmp.bam \
			> ${fastq_clean_dir}/${id}/${id}_unmapped_paired_tmp.bam 

		$samtools sort -n -m ${samtools_m}G -@ 2 \
			${fastq_clean_dir}/${id}/${id}_unmapped_paired_tmp.bam  \
			-o ${fastq_clean_dir}/${id}/${id}_unmapped_paired_sorted_tmp.bam

		$samtools fastq -@ 8 \
			${fastq_clean_dir}/${id}/${id}_unmapped_paired_sorted_tmp.bam \
			-1 ${fastq_clean_dir}/${id}/${id}_R1.fastq.gz \
			-2 ${fastq_clean_dir}/${id}/${id}_R2.fastq.gz \
			-0 /dev/null -s /dev/null -n
	elif [ -f "${fastq_trimmed_dir}/${id}/${id}_trimmed.fq.gz" ]; then
		# TODO: test pipeline with unpaired data
		bowtie2 -p ${num_cores} -x ${hum_genome_ref} \
			-U ${fastq_trimmed_dir}/${id}/${id}_trimmed.fq.gz \
			-S ${fastq_clean_dir}/${id}/${id}_mapped_and_unmapped_tmp.sam

		samtools view -bS ${fastq_clean_dir}/${id}/${id}_mapped_and_unmapped_tmp.sam \
			> ${fastq_clean_dir}/${id}/${id}_mapped_and_unmapped_tmp.bam

		samtools view -b -f 4 \
			${fastq_clean_dir}/${id}/${id}_mapped_and_unmapped_tmp.bam \
			> ${fastq_clean_dir}/${id}/${id}_unmapped_unpaired_tmp.bam

		samtools sort -n -m ${samtools_m}G -@ 2 \
			${fastq_clean_dir}/${id}/${id}_unmapped_unpaired_tmp.bam  \
			-o ${fastq_clean_dir}/${id}/${id}_unmapped_unpaired_sorted_tmp.bam

		samtools fastq -@ 8 \
			$${fastq_clean_dir}/${id}/${id}_unmapped_unpaired_sorted_tmp.bam \
			-1 ${fastq_clean_dir}/${id}/${id}_RU.fastq.gz \
			-0 /dev/null -s /dev/null -n
	else
		echo "$(timestamp): quality_check_fastq: ERROR! trimmed fastq files not found"
		exit 1
	fi

	# check if cleaned file(s) created
	if ls ${fastq_clean_dir}/${id}/*R*fastq.gz 1> /dev/null 2>&1; then
		echo "$(timestamp): quality_check_fastq: clean fastq files created"
		rm ${fastq_clean_dir}/${id}/*tmp*
		rm ${fastq_trimmed_dir}/${id}/*fq.gz
	else
		echo "$(timestamp): quality_check_fastq: ERROR! clean fastq files not found"
		exit 1
	fi
}
