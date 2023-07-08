###############################################################################
#       Aydin Karatas
#		Project Coprolite Viromes
#		assemble_libraries.sh 
###############################################################################
#!/bin/bash
for FILE in $HOME/project_coprolite_viromes/general_bash_functions/* ; do source $FILE ; done
source /u/local/Modules/default/init/modules.sh
module load python
source $HOME/my_py/bin/activate


# create final.contigs.fa with megahit assembly from fastq/fasta files
assemble_libraries() {
	local sample=$1
	local fastq_trimmed_dir=$2
	local assembly_dir=$3
	local assembly_extra_dir=$4
	local num_cores=$5

	# identyify all libraries
	python3 $HOME/project_coprolite_viromes/megahit_assembly/identify_fastq_files.py $fastq_trimmed_dir > $assembly_dir/id_paths.txt
	single_end_data="$(head -n 1 $assembly_dir/id_paths.txt | cut -f 1)"
	paired_end_data_1="$(head -n 1 $assembly_dir/id_paths.txt | cut -f 2)"
	paired_end_data_2="$(head -n 1 $assembly_dir/id_paths.txt | cut -f 3)"
	rm $assembly_dir/id_paths.txt

	# assembly fastq.gz files with meaghit
	echo "$(timestamp): assemble_libraries: $sample"
	echo "__________________________________________________"
	megahit_assembler "$assembly_extra_dir" "$single_end_data" "$paired_end_data_1" "$paired_end_data_2" "$num_cores"
	echo "__________________________________________________"

	# Check if assembly was completed
	if ls "$assembly_extra_dir/final.contigs.fa" 1> /dev/null 2>&1; then
		echo "$(timestamp): assemble_libraries: final contigs file created"
		# Check if the file is empty
		if ! [ -s "$assembly_extra_dir/final.contigs.fa" ]; then
			echo "$(timestamp): assemble_libraries: ERROR! contigs file is empty"
			exit 1
		fi
	else
		echo "$(timestamp): assemble_libraries: ERROR! final contigs file not found"
		exit 1
	fi

	# move contigs file and log file to the main assembly directory
	mv $assembly_extra_dir/final.contigs.fa \
		${assembly_dir}/${origin}_${sample}_all_contigs.fa
	mv $assembly_extra_dir/log \
		${assembly_dir}/${origin}_${sample}_log.txt
}
