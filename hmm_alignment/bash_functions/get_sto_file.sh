#!/bin/bash
###############################################################################
#       Aydin Karatas
#		Project Coprolite Viromes
#		get_sto_file.sh 
###############################################################################


get_sto_file() {
    predicted_orfs=$1
	aligned_orfs=$2
    sto_file=$3

    # check if sto file was aleady created
    if ls $sto_file 1> /dev/null 2>&1; then
		echo "$(timestamp): get_sto_file: sto format file already created"
		return 0
	fi

    # check if amino acid fasta exists
    if ls ${predicted_orfs}.gz 1> /dev/null 2>&1; then
		echo "$(timestamp): get_sto_file: decompressing amino acid fasta file"
		gunzip ${predicted_orfs}.gz
	elif ls ${predicted_orfs} 1> /dev/null 2>&1; then
        echo "$(timestamp): get_sto_file: amino acid fasta file already decompressed"
    else
        echo "$(timestamp): get_sto_file: ERROR! amino acid fasta file not found"
        exit 1
    fi

	# align fasta sequences
	mafft --auto $predicted_orfs > $aligned_orfs

    # reformat fasta to sto
    $esl_reformat stockholm $aligned_orfs > $sto_file

    # compress fasta files
    gzip $predicted_orfs
	gzip $aligned_orfsmaf	

    # check that sto file was created and is not empty
	if ls $sto_file 1> /dev/null 2>&1; then
		echo "$(timestamp): get_sto_file: sto file created"
		# scheck if sto file is empty
		if ! [ -s "$sto_file"  ]; then
			echo "$(timestamp): get_sto_file: ERROR! sto file is empty"
			exit 1
		fi
	else
		echo "$(timestamp): get_sto_file: ERROR! sto files not found"
		exit 1
	fi
}
