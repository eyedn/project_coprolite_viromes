###############################################################################
#       Aydin Karatas
#		Project Coprolite Viromes
#		get_hosts.sh 
###############################################################################


# use PhaTYP from PhaBOX to predict viral lifestyles
get_lifestyles() {
    local sample=$1
	local contigs_file=$2
	local predict_dir=$3
	local num_cores=$4

	# check if predictions already completed
    if ls $predict_dir/out/cherry_prediction.csv 1> /dev/null 2>&1; then
        echo "$(timestamp): get_hosts: host predictions already completed"
        return 0
    fi

    # create predictions dir for this sample
    mkdir -p $predict_dir

    echo "$(timestamp): get_hosts: $sample"
	echo "__________________________________________________"
    cd $phabox
    python3 Cherry_single.py \
        --contigs $contigs_file \
        --threads 8 \
        --len 100 \
        --rootpth $predict_dir 
    cd $HOME
    echo "__________________________________________________"

    # Check if predictions were completed
	if ls $predict_dir/out/cherry_prediction.csv 1> /dev/null 2>&1; then
		echo "$(timestamp): get_hosts: host predictions file created"
		# Check if the file is empty
		if ! [ -s "$predict_dir/out/cherry_prediction.csv" ]; then
			echo "$(timestamp): get_hosts: ERROR! host predictions file is empty"
			exit 1
		fi
	else
		echo "$(timestamp): get_hosts: ERROR! host predictions file not found"
		exit 1
	fi
}
