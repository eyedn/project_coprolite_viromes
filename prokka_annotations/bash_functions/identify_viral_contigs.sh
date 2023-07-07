###############################################################################
#       Aydin Karatas
#		Project Coprolite Viromes
#		identify_viral_contigs.sh 
###############################################################################
#!/bin/bash
source $HOME/project_coprolite_viromes/general_bash_functions/timestamp.sh
source /u/local/Modules/default/init/modules.sh
module load python
source $HOME/my_py/bin/activate


# create a contigs file with only contigs with viral annotations
identify_viral_contigs() {
	all_contigs=$1
	gff_file=$2
	viral_contigs=$3

	# if viral contig identication already happend, return early
	if ls $viral_contigs 1> /dev/null 2>&1; then
		echo "$(timestamp): identify_viral_contigs: viral contigs file found. identification already completed"
		return 0
	fi

	python3 $HOME/project_coprolite_viromes/prokka_annotations/identify_viral_contigs.py \
		$all_contigs $gff_file > $viral_contigs

	# Check if identification was completed
	if ls $viral_contigs 1> /dev/null 2>&1; then
		echo "$(timestamp): identify_viral_contigs: viral contigs files created"
		# Check if the tbl file is empty
		if ! [ -s "$viral_contigs"  ]; then
			echo "$(timestamp): identify_viral_contigs: ERROR! viral contigs file is empty"
			rm $viral_contigs
			exit 1
		fi
	else
		echo "$(timestamp): identify_viral_contigs: ERROR! viral contigs file files not found"
		exit 1
	fi
}