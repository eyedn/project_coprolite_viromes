#!/bin/bash
###############################################################################
#       Aydin Karatas
#       Project Coprolite Viromes
#       get_phages.sh
###############################################################################
# Identify phage contigs with PhaBOX PhaMer.
get_phages() {
    local sample=$1
	local contigs_file=$2
	local predict_dir=$3
	local num_cores=$4


    # Reuse a completed PhaMer phage-identification table.
    if [ -s "$predict_dir/out/phamer_prediction.csv" ]; then
        echo "$(timestamp): get_phages: phage predictions already completed"
        return 0
    fi

    # Decompress the gzipped contig input before phage identification.
    if ls ${contigs_file}.gz 1> /dev/null 2>&1; then
        gunzip ${contigs_file}.gz
    fi

    # Create the PhaMer output directory.
    mkdir -p $predict_dir

    echo "$(timestamp): get_phages: $sample"
	echo "__________________________________________________"
    # Run PhaMer to identify phage contigs in the assembled sequences.
    cd $phabox
    python3 PhaMer_single.py \
        --contigs $contigs_file \
        --threads 8 \
        --len 100 \
        --rootpth $predict_dir 
    cd $HOME
    echo "__________________________________________________"

    # Recompress the contig input after PhaMer finishes.
    if ls ${contigs_file} 1> /dev/null 2>&1; then
        gzip ${contigs_file}
    fi

    # Require a nonempty PhaMer prediction table before returning.
	if ls $predict_dir/out/phamer_prediction.csv 1> /dev/null 2>&1; then
		echo "$(timestamp): get_phages: phage predictions file created"
		# Reject an empty output table as an incomplete prediction.
		if ! [ -s "$predict_dir/out/phamer_prediction.csv" ]; then
			echo "$(timestamp): get_phages: ERROR! phage predictions file is empty"
			exit 1
		fi
	else
		echo "$(timestamp): get_phages: ERROR! phage predictions file not found"
		exit 1
	fi
}
