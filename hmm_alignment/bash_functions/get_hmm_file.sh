###############################################################################
#       Aydin Karatas
#		Project Coprolite Viromes
#		get_hmm_file.sh 
###############################################################################


get_hmm_file() {
    sto_file=$1
    hmm_file=$2

    # check if hmm file was aleady created
    if ls $hmm_file 1> /dev/null 2>&1; then
		echo "$(timestamp): get_hmm_file: hmm file already created"
		return 0
	fi

    # check if sto file exists
    if ls ${sto_file}.gz 1> /dev/null 2>&1; then
		echo "$(timestamp): get_hmm_file: sto file found"
    else
        echo "$(timestamp): get_hmm_file: ERROR! sto file not found"
        exit 1
    fi

    # build hmm file for future alignment
    hmmbuild $hmm_file $sto_file

    # check if hmm_file was created and is not empty
	if ls $hmm_file 1> /dev/null 2>&1; then
		echo "$(timestamp): get_hmm_file: hmm_file created"
		# scheck if hmm_file is empty
		if ! [ -s "$hmm_file"  ]; then
			echo "$(timestamp): get_hmm_file: ERROR! hmm_file is empty"
			exit 1
		fi
	else
		echo "$(timestamp): get_hmm_file: ERROR! hmm_files not found"
		exit 1
	fi
}