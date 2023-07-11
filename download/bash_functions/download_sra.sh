###############################################################################
#       Aydin Karatas
#       Project Coprolite Viromes
#       download_sra.sh 
###############################################################################
#!/bin/bash
cd $HOME/project_coprolite_viromes
for FILE in general_bash_functions/* ; do source $FILE ; done


# use prefetch to download sra file of accession id
download_sra() {
	local id=$1
	local sra_dir=$2

	# if sra download already happend, skip to next sra to fastq conversion
	if ls ${sra_dir}/${id}/${id}.sra* 1> /dev/null 2>&1; then
		echo "$(timestamp): download_sra: ${sra_dir}/${id}/${id}.sra* found. continuing to fasterq-dump"
		return 0
	fi

	# prefetch sra
	$prefetch --type sra ${id} -O ${sra_dir} --max-size 100G

	# check if sra was successfully downloaded; move it into appropriate directory if needed
	if ls ${sra_dir}/${id}/${id}.sra* 1> /dev/null 2>&1; then
		echo "$(timestamp): download_sra: ${sra_dir}/${id}/${id}.sra* created"
	else
		echo "$(timestamp): download_sra: ERROR! sra* file not detected"
		exit 1
	fi
}
