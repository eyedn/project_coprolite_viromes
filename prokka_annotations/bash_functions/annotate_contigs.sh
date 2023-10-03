###############################################################################
#       Aydin Karatas
#		Project Coprolite Viromes
#		annotate_contigs.sh 
###############################################################################
#!/bin/bash


# generate informative files by annotating contigs file 
annotate_contigs() {
	local sample=$1
	local contigs_file=$2
	local custom_db=$3
	local annot_dir=$4
	local type=$5
	local label=$6
	local num_cores=$7

	# if annotation already happend, skip return early
	if ls $annot_dir 1> /dev/null 2>&1; then
		echo "$(timestamp): annotate_contigs: annotation directory found. annotation already completed"
		return 0
	fi

	# decompress contigs file if needed
	if ls ${contigs_file}.gz 1> /dev/null 2>&1; then
		gunzip ${contigs_file}.gz
	fi

	# annotate using prokka
	echo "$(timestamp): annotate_contigs: $sample"
	echo "__________________________________________________"
	prokka_annotator "$sample" "$contigs_file" "$custom_db" "$annot_dir" \
		"$type" "$label" "$num_cores"
	echo "__________________________________________________"

	# compress contigs file
	if ls ${contigs_file} 1> /dev/null 2>&1; then
		gzip ${contigs_file}
	fi

	# Check if annotation was completed
	if ls $annot_dir 1> /dev/null 2>&1; then
		echo "$(timestamp): annotate_contigs: annotation files created"
		# Check if the tbl file is empty
		if ! [ -s "$annot_dir/"*.tbl  ]; then
			echo "$(timestamp): annotate_contigs: ERROR! .tbl file is empty"
			exit 1
		fi
	else
		echo "$(timestamp): annotate_contigs: ERROR! annotation files not found"
		exit 1
	fi
}
