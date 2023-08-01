###############################################################################
#       Aydin Karatas
#		Project Coprolite Viromes
#		get_sto_file.sh 
###############################################################################


get_sto_file() {
    aa_file=$1
    sto_file=$2

    # check if sto file was aleady created
    if ls $sto_file 1> /dev/null 2>&1; then
		echo "$(timestamp): get_sto_file: sto format file already created"
		return 0
	fi

    # check if amino acid fasta exists
    if ls ${aa_file}.gz 1> /dev/null 2>&1; then
		echo "$(timestamp): get_sto_file: decompressing amino acid fasta file"
		gunzip ${aa_file}.gz
	elif ls ${aa_file} 1> /dev/null 2>&1; then
        echo "$(timestamp): get_sto_file: amino acid fasta file already decompressed"
    else
        echo "$(timestamp): get_sto_file: ERROR! amino acid fasta file not found"
        exit 1
    fi

    # reformat fastsa to sto
    esl-reformat stockholm $aa_file > $sto_file

    # compress fasta file
    gzip $aa_file

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