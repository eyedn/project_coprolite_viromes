#!/bin/bash
###############################################################################
#       Aydin Karatas
#       Project Coprolite Viromes
#       quality_control.sh 
###############################################################################


# use trim galore to remove adapters and trim reads for quality
quality_control() {
	local id=$1
	local fastq_raw_dir=$2
	local fastq_trimmed_dir=$3
	local fastq_stats=$4
	local num_cores=$5

	# check if fastq files already trimmed
	if ls ${fastq_trimmed_dir}/${id}_DONE.txt 1> /dev/null 2>&1; then
		echo "$(timestamp): quality_control: ${fastq_trimmed_dir}/${id}_DONE.txt found."
		return 0
	fi

	# rename sralite fastq files for simplicity
	if [ -f "${fastq_raw_dir}/${id}/${id}.sralite_1.fastq.gz" ] && \
	[ -f "${fastq_raw_dir}/${id}/${id}.sralite_2.fastq.gz" ]; then
		mv ${fastq_raw_dir}/${id}/${id}.sralite_1.fastq.gz \
			${fastq_raw_dir}/${id}/${id}_1.fastq.gz
		mv ${fastq_raw_dir}/${id}/${id}.sralite_2.fastq.gz \
			${fastq_raw_dir}/${id}/${id}_2.fastq.gz
	elif [ -f "${fastq_raw_dir}/${id}/${id}.sralite.fastq.gz" ]; then
		mv ${fastq_raw_dir}/${id}/${id}.sralite.fastq.gz \
			${fastq_raw_dir}/${id}/${id}.fastq.gz
	fi

	# establish number of cores to use
	if [ "$num_cores" -gt "$trim_galore_cores" ]; then
		cores_to_use="$trim_galore_cores";
	else
		cores_to_use="$num_cores"
	fi

	# check for paired on unpaired reads; proceed to...
	# 	...(1) saving raw reads stats
	#	...(2) trimming adapters, low quality base, small reads
	mkdir -p $fastq_trimmed_dir
	if [ -f "${fastq_raw_dir}/${id}/${id}_1.fastq.gz" ] && \
	[ -f "${fastq_raw_dir}/${id}/${id}_2.fastq.gz" ]; then
		# (1) for paired
		num_1=$($seqtk comp ${fastq_raw_dir}/${id}/${id}_1.fastq.gz | wc -l)
		num_2=$($seqtk comp ${fastq_raw_dir}/${id}/${id}_2.fastq.gz | wc -l)
		echo $((num_1 + num_2)) >> $fastq_stats

		len_1=$($seqtk comp ${fastq_raw_dir}/${id}/${id}_1.fastq.gz | awk '{sum += $2} END {print sum}')
		len_2=$($seqtk comp ${fastq_raw_dir}/${id}/${id}_2.fastq.gz | awk '{sum += $2} END {print sum}')
		echo $((len_1 + len_2)) >> $fastq_stats

		# (2) for paired
		$trim_galore \
			--paired \
			-o ${fastq_trimmed_dir}/${id} \
			--basename ${id} \
			--gzip \
			-j $cores_to_use \
			${fastq_raw_dir}/${id}/${id}_1.fastq.gz \
			${fastq_raw_dir}/${id}/${id}_2.fastq.gz
	elif [ -f "${fastq_raw_dir}/${id}/${id}.fastq.gz" ]; then
		# (1) for unpaired
		$seqtk comp ${fastq_raw_dir}/${id}/${id}.fastq.gz | wc -l >> $fastq_stats
		$seqtk comp ${fastq_raw_dir}/${id}/${id}.fastq.gz | awk '{sum += $2} END {print sum}' >> $fastq_stats

		# (2) for unpaired
		$trim_galore \
			-o ${fastq_trimmed_dir}/${id} \
			--basename ${id} \
			--gzip \
			-j $cores_to_use \
			${fastq_raw_dir}/${id}/${id}.fastq.gz
	fi

	# check if paired or unpaired reads trimmed; proceed with...
	#	...saving trimmed reads data
	if ls ${fastq_trimmed_dir}/${id}/*_1.fq.gz 1> /dev/null 2>&1; then
		num_1=$($seqtk comp ${fastq_trimmed_dir}/${id}/${id}_val_1.fq.gz | wc -l)
		num_2=$($seqtk comp ${fastq_trimmed_dir}/${id}/${id}_val_2.fq.gz | wc -l)
		echo $((num_1 + num_2)) >> $fastq_stats

		len_1=$($seqtk comp ${fastq_trimmed_dir}/${id}/${id}_val_1.fq.gz | awk '{sum += $2} END {print sum}')
		len_2=$($seqtk comp ${fastq_trimmed_dir}/${id}/${id}_val_2.fq.gz | awk '{sum += $2} END {print sum}')
		echo $((len_1 + len_2)) >> $fastq_stats
	elif ls ${fastq_trimmed_dir}/${id}/*.fq.gz 1> /dev/null 2>&1; then
		$seqtk comp ${fastq_trimmed_dir}/${id}/${id}_trimmed.fq.gz | wc -l >> $fastq_stats
		$seqtk comp ${fastq_trimmed_dir}/${id}/${id}_trimmed.fq.gz | awk '{sum += $2} END {print sum}' >> $fastq_stats
	else
		echo "$(timestamp): quality_control: ERROR! trimmed fastq files not found"
		exit 1
	fi

	# create file in indicate compeletion of quality control
	touch ${fastq_trimmed_dir}/${id}_DONE.txt
	echo "$(timestamp): quality_control: trimmed fastq files created"
	rm -r ${fastq_raw_dir}/${id}
}
