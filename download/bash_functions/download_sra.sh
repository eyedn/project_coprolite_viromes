#!/bin/bash
###############################################################################
#       Aydin Karatas
#       Project Coprolite Viromes
#       download_sra.sh 
###############################################################################


# use prefetch to download sra file of accession id
download_sra() {
	local id=$1
	local sra_dir=$2

	# check if sra download was already complete
	if ls ${sra_dir}/${id}_DONE.txt 1> /dev/null 2>&1; then
		echo "$(timestamp): download_sra: ${sra_dir}/${id}_DONE.txt found."
		return 0
	fi

	# prefetch sra
	mkdir -p ${sra_dir}
	$prefetch --type sra ${id} -O ${sra_dir} --max-size 100G

	# check if sra was successfully downloaded
	if ls ${sra_dir}/${id}/${id}.sra* 1> /dev/null 2>&1; then
		echo "$(timestamp): download_sra: ${sra_dir}/${id}/${id}.sra* created"
	else
		echo "$(timestamp): download_sra: ERROR! sra* file not detected"
		exit 1
	fi

	# create file to indicate successful complete for sra download
	touch ${sra_dir}/${id}_DONE.txt
}
