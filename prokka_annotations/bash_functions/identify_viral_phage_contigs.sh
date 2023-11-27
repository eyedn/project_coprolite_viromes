#!/bin/bash
###############################################################################
#       Aydin Karatas
#		Project Coprolite Viromes
#		identify_viral_phage_contigs.sh 
###############################################################################


# create a contigs file with only contigs with viral annotations
identify_viral_phage_contigs() {
	all_contigs=$1
	phage_contigs=$2
	gff_file=$3
	viral_phage_contigs=$4

	# if viral contig identication already happend, return early
	if ls $viral_phage_contigs 1> /dev/null 2>&1; then
		echo "$(timestamp): identify_viral_phage_contigs: viral contigs file found. identification already completed"
		return 0
	fi

	# decompress contigs file if needed
	if ls ${all_contigs}.gz 1> /dev/null 2>&1; then
		gunzip ${all_contigs}.gz
	fi
	if ls ${phage_contigs}.gz 1> /dev/null 2>&1; then
		gunzip ${phage_contigs}.gz
	fi
	
	python3 prokka_annotations/identify_viral_phage_contigs.py \
		$all_contigs $phage_contigs $gff_file > $viral_phage_contigs

	if ls ${all_contigs} 1> /dev/null 2>&1; then
		gzip ${all_contigs}
	fi
	if ls ${phage_contigs} 1> /dev/null 2>&1; then
		gzip ${phage_contigs}
	fi

	# Check if identification was completed
	if ls $viral_phage_contigs 1> /dev/null 2>&1; then
		echo "$(timestamp): identify_viral_phage_contigs: viral contigs files created"
		# Check if the tbl file is empty
		if ! [ -s "$viral_phage_contigs"  ]; then
			echo "$(timestamp): identify_viral_phage_contigs: ERROR! viral contigs file is empty"
			rm $viral_phage_contigs
			exit 1
		fi
	else
		echo "$(timestamp): identify_viral_phage_contigs: ERROR! viral contigs file files not found"
		exit 1
	fi
}
