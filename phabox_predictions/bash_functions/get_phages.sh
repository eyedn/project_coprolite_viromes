#!/bin/bash
###############################################################################
#       Aydin Karatas
#		Project Coprolite Viromes
#		get_phages.sh 
###############################################################################


# use PhaTYP from PhaBOX to predict viral lifestyles
get_phages() {
    local sample=$1
	local contigs_file=$2
	local predict_dir=$3
	local num_cores=$4


    # check if predictions already completed
    if ls $predict_dir/out/phamer_prediction.csv 1> /dev/null 2>&1; then
        echo "$(timestamp): get_phages: phage predictions already completed"
        return 0
    fi

    # decompress contigs file if needed
    if ls ${contigs_file}.gz 1> /dev/null 2>&1; then
        gunzip ${contigs_file}.gz
    fi

    # create predictions dir for this sample
    mkdir -p $predict_dir

    echo "$(timestamp): get_phages: $sample"
	echo "__________________________________________________"
    cd $phabox
    python3 PhaMer_single.py \
        --contigs $contigs_file \
        --threads 8 \
        --len 100 \
        --rootpth $predict_dir 
    cd $HOME
    echo "__________________________________________________"

    # compress contigs file
    if ls ${contigs_file} 1> /dev/null 2>&1; then
        gzip ${contigs_file}
    fi

    # Check if predictions were completed
	if ls $predict_dir/out/phamer_prediction.csv 1> /dev/null 2>&1; then
		echo "$(timestamp): get_phages: phage predictions file created"
		# Check if the file is empty
		if ! [ -s "$predict_dir/out/phamer_prediction.csv" ]; then
			echo "$(timestamp): get_phages: ERROR! phage predictions file is empty"
			exit 1
		fi
	else
		echo "$(timestamp): get_phages: ERROR! phage predictions file not found"
		exit 1
	fi
}
