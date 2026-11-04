#!/bin/bash
###############################################################################
#       Aydin Karatas
#       Project Coprolite Viromes
#       get_hosts.sh
###############################################################################


# predict phage hosts with PhaBOX CHERRY.
get_hosts() {
    local sample=$1
	local contigs_file=$2
	local predict_dir=$3
	local num_cores=$4

	# reuse a completed CHERRY host-prediction table.
    if [ -s "$predict_dir/out/cherry_prediction.csv" ]; then
        echo "$(timestamp): get_hosts: host predictions already completed"
        return 0
    fi

    # decompress the gzipped contig input before host prediction.
    if ls ${contigs_file}.gz 1> /dev/null 2>&1; then
        gunzip ${contigs_file}.gz
    fi

    # create the CHERRY output directory.
    mkdir -p $predict_dir

    echo "$(timestamp): get_hosts: $sample"
	echo "__________________________________________________"
    # run CHERRY to predict a host for each supplied phage contig.
    cd $phabox
    python3 Cherry_single.py \
        --contigs $contigs_file \
        --threads 8 \
        --len 100 \
        --rootpth $predict_dir 
    cd $HOME
    echo "__________________________________________________"

    # recompress the contig input after CHERRY finishes.
    if ls ${contigs_file} 1> /dev/null 2>&1; then
        gzip ${contigs_file}
    fi

    # require a nonempty CHERRY prediction table before returning.
	if ls $predict_dir/out/cherry_prediction.csv 1> /dev/null 2>&1; then
		echo "$(timestamp): get_hosts: host predictions file created"
		# reject an empty output table as an incomplete prediction.
		if ! [ -s "$predict_dir/out/cherry_prediction.csv" ]; then
			echo "$(timestamp): get_hosts: ERROR! host predictions file is empty"
			exit 1
		fi
	else
		echo "$(timestamp): get_hosts: ERROR! host predictions file not found"
		exit 1
	fi
}
