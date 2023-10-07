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
	local fastq_stats=$4
	local num_cores=$5

	# check if clean file(s) already exists, return from pre-processing
	if ls ${fastq_clean_dir}/${id}_DONE.txt 1> /dev/null 2>&1; then
		echo "$(timestamp): remove_human_reads: ${fastq_clean_dir}/${id}_DONE.txt found."
		return 0
	fi

	# check if paired or unpaired reads trimmed; proceed with...
	#	removing reads that map to reference human genome
	mkdir -p ${fastq_clean_dir}/${id}
	if [ -f "${fastq_trimmed_dir}/${id}/${id}_val_1.fq.gz" ] && \
	[ -f "${fastq_trimmed_dir}/${id}/${id}_val_2.fq.gz" ]; then
		$bowtie2 \
			-p $num_cores \
			-x $hum_genome_ref \
			-1 ${fastq_trimmed_dir}/${id}/${id}_val_1.fq.gz \
			-2 ${fastq_trimmed_dir}/${id}/${id}_val_2.fq.gz \
			--un-conc-gz ${fastq_clean_dir}/${id}/${id}_R%.fastq.gz \
			-S ${fastq_clean_dir}/${id}/${id}_SAMPLE_mapped_and_unmapped.sam
	elif [ -f "${fastq_trimmed_dir}/${id}/${id}_trimmed.fq.gz" ]; then
		$bowtie2 \
			-p $num_cores \
			-x $hum_genome_ref \
			-U ${fastq_trimmed_dir}/${id}/${id}_trimmed.fq.gz \
			--un-gz ${fastq_clean_dir}/${id}/${id}_RU.fastq.gz \
			-S ${fastq_clean_dir}/${id}/${id}_SAMPLE_mapped_and_unmapped.sam
	else
		echo "$(timestamp): remove_human_reads: ERROR! trimmed fastq files not found"
		exit 1
	fi

	# check if bowtie2 ran correctly
	if [ $? -ne 0 ]; then
		echo "$(timestamp): Error running bowtie2 for sample $id"
		exit 1
	else
		echo "$(timestamp): bowtie2 results"
		ls ${fastq_clean_dir}/${id}
	fi

	# check if paired or unpaired reads clearned; proceed with...
	#	...saving trimmed reads data
	if ls ${fastq_clean_dir}/${id}/*_R1.fastq.gz 1> /dev/null 2>&1; then
		num_1=$($seqtk comp ${fastq_clean_dir}/${id}/${id}_R1.fastq.gz | wc -l)
		num_2=$($seqtk comp ${fastq_clean_dir}/${id}/${id}_R2.fastq.gz | wc -l)
		echo $((num_1 + num_2)) >> $fastq_stats

		len_1=$($seqtk comp ${fastq_clean_dir}/${id}/${id}_R1.fastq.gz | awk '{sum += $2} END {print sum}')
		len_2=$($seqtk comp ${fastq_clean_dir}/${id}/${id}_R2.fastq.gz | awk '{sum += $2} END {print sum}')
		echo $((len_1 + len_2)) >> $fastq_stats
	elif ls ${fastq_clean_dir}/${id}/*.fastq.gz 1> /dev/null 2>&1; then
		$seqtk comp ${fastq_clean_dir}/${id}/${id}_RU.fastq.gz | wc -l >> $fastq_stats
		$seqtk comp ${fastq_clean_dir}/${id}/${id}_RU.fastq.gz | awk '{sum += $2} END {print sum}' >> $fastq_stats
	else
		echo "$(timestamp): remove_human_reads: ERROR! clean fastq files not found"
		exit 1
	fi

	# create file indicating completion of fastq cleaning
	touch ${fastq_clean_dir}/${id}_DONE.txt
	echo "$(timestamp): remove_human_reads: clean fastq files created"
	rm $fastq_trimmed_dir/$id/*fq*
	rm $fastq_clean_dir/$id/*sam
}
