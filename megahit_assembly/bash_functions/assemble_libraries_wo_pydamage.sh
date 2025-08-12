#!/bin/bash
###############################################################################
#       Aydin Karatas
#		Project Coprolite Viromes
#		assemble_libraries_wo_pydamage.sh 
###############################################################################


# create final.contigs.fa with megahit assembly from fastq/fasta files
assemble_libraries_wo_pydamage() {
	local sample=$1
	local fastq_clean_dir=$2
	local assembly_dir=$3
	local assembly_extra_dir=$4
	local num_cores=$5

	# identyify all libraries
	mkdir -p $assembly_dir
	echo "$(timestamp): ${fastq_clean_dir} contents:"
	ls $fastq_clean_dir/*
	python3 megahit_assembly/identify_fastq_files.py $fastq_clean_dir > $assembly_dir/id_paths.txt
	single_end_data="$(head -n 1 $assembly_dir/id_paths.txt | cut -f 1)"
	paired_end_data_1="$(head -n 1 $assembly_dir/id_paths.txt | cut -f 2)"
	paired_end_data_2="$(head -n 1 $assembly_dir/id_paths.txt | cut -f 3)"

	# assembly fastq.gz files with meaghit
	echo "$(timestamp): assemble_libraries_wo_pydamage: $sample without pydamage"
	echo "__________________________________________________"
	megahit_assembler_wo_pydamage "$assembly_extra_dir" "$single_end_data" "$paired_end_data_1" "$paired_end_data_2" "$num_cores"
	echo "__________________________________________________"

	# Check if assembly was completed
	if ls "$assembly_extra_dir/final.contigs.fa" 1> /dev/null 2>&1; then
		echo "$(timestamp): assemble_libraries_wo_pydamage: final contigs file created"
		# Check if the file is empty
		if ! [ -s "$assembly_extra_dir/final.contigs.fa" ]; then
			echo "$(timestamp): assemble_libraries_wo_pydamage: ERROR! contigs file is empty"
			exit 1
		fi
	else
		echo "$(timestamp): assemble_libraries_wo_pydamage: ERROR! final contigs file not found"
		exit 1
	fi

	# move contigs file and log file to the main assembly directory
	mv $assembly_extra_dir/final.contigs.fa \
		${assembly_dir}/${origin}_${sample}_all_contigs.fa
	mv $assembly_extra_dir/log \
		${assembly_dir}/${origin}_${sample}_log.txt

	# cleanup helper files
    rm -f "$assembly_dir/id_paths.txt"

    # we are done with the extra dir; remove it entirely
    rm -rf "$assembly_extra_dir"
}