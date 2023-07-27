###############################################################################
#       Aydin Karatas
#		Project Coprolite Viromes
#		get_families.sh 
###############################################################################


# use PhaTYP from PhaBOX to predict viral lifestyles
get_families() {
    local sample=$1
	local contigs_file=$2
	local predict_dir=$3
	local num_cores=$4

	# check if predictions already completed
    if ls $predict_dir/out/phagcn_prediction.csv 1> /dev/null 2>&1; then
        echo "$(timestamp): get_families: taxonomic predictions already completed"
        return 0
    fi

    # decompress contigs file if needed
    if ls ${contigs_file}.gz 1> /dev/null 2>&1; then
        gunzip ${contigs_file}.gz
    fi

    # create predictions dir for this sample
    mkdir -p $predict_dir

    echo "$(timestamp): get_families: $sample"
	echo "__________________________________________________"
    cd $phabox
    python3 PhaGCN_single.py \
        --contigs $contigs_file \
        --threads 8 \
        --len 100 \
        --rootpth $predict_dir 
    cd $HOME
    echo "__________________________________________________"

    # compress contigs file
    if ls ${contigs_file}.gz 1> /dev/null 2>&1; then
        gzip ${contigs_file}
    fi

    # Check if predictions were completed
	if ls $predict_dir/out/phagcn_prediction.csv 1> /dev/null 2>&1; then
		echo "$(timestamp): get_families: taxonomic predictions file created"
		# Check if the file is empty
		if ! [ -s "$predict_dir/out/phagcn_prediction.csv" ]; then
			echo "$(timestamp): get_families: ERROR! taxonomic predictions file is empty"
			exit 1
		fi
	else
		echo "$(timestamp): get_families: ERROR! taxonomic predictions file not found"
		exit 1
	fi
}
