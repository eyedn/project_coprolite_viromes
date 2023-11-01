#!/bin/bash
###############################################################################
#       Aydin Karatas
#		Project Coprolite Viromes
#		align_w_db.sh 
###############################################################################


align_w_db() {
    sample=$1
    orfs_file=$2
    db_file=$3
    sample_align_dir=$4
	num_cores=$5
	incE=$6

    # define output variables
    results_out="${sample_align_dir}/results.txt"
    table_out="${sample_align_dir}/table.txt"
	table_out_signif="${sample_align_dir}/table_signif.txt"

    # check if outputs already created
    if ls $results_out 1> /dev/null 2>&1; then
		echo "$(timestamp): align_w_db: results.txt already created"
		return 0
	fi
    if ls $table_out 1> /dev/null 2>&1; then
		echo "$(timestamp): align_w_db: table.txt already created"
		return 0
	fi

    # check both hmm and db files exist
    if ls $orfs_file 1> /dev/null 2>&1; then
		echo "$(timestamp): align_w_db: orfs_file found"
	elif ls ${orfs_file}.gz /dev/null 2>&1; then
		echo "$(timestamp): align_w_db: decompressing orfs_file"
		gunzip ${orfs_file}.gz
	else
        echo "$(timestamp): align_w_db: ERROR! orfs_file not found"
        exit 1
    fi
    if ls $db_file 1> /dev/null 2>&1; then
		echo "$(timestamp): align_w_db: database found"
	else
        echo "$(timestamp): align_w_db: ERROR! database not found"
        exit 1
    fi

    # align orfs_file to database
	mkdir -p $sample_align_dir
    $hmmsearch \
        -o $results_out \
        --tblout $table_out \
        --cpu $num_cores \
        --incE $incE \
		$db_file \
        $orfs_file 
	gzip $orfs_file

    # check that output files were created and are not empty
	if ls $results_out 1> /dev/null 2>&1; then
		echo "$(timestamp): align_w_db: results.txt created"
		# scheck if sto file is empty
		if ! [ -s "$results_out"  ]; then
			echo "$(timestamp): align_w_db: ERROR! results.txt is empty"
			exit 1
		fi
	else
		echo "$(timestamp): align_w_db: ERROR! results.txt not found"
		exit 1
	fi
    if ls $table_out 1> /dev/null 2>&1; then
		echo "$(timestamp): align_w_db: table.txt created"
		# scheck if sto file is empty
		if ! [ -s "$table_out"  ]; then
			echo "$(timestamp): align_w_db: ERROR! table.txt is empty"
			exit 1
		fi
	else
		echo "$(timestamp): align_w_db: ERROR! table.txt not found"
		exit 1
	fi
}