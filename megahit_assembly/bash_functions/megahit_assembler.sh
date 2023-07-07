###############################################################################
#       Aydin Karatas
#		Project Coprolite Viromes
#		assembly_functions.sh 
###############################################################################
#!/bin/bash
source $HOME/project_coprolite_viromes/general_bash_functions/timestamp.sh
source /u/local/Modules/default/init/modules.sh
module load anaconda3
conda activate myconda


# contains the megahit command to assembly fastq/fasta files
megahit_assembler() {
	# define argument variables
	local output_dir=$1
	local single_end_data=$2
	local paired_end_data_1=$3
	local paired_end_data_2=$4
	local num_cores=$5

	echo "$(timestamp): megahit_assembler: single-ended files: $single_end_data"
	echo "$(timestamp): megahit_assembler: paired-ended (1) files: $paired_end_data_1"
	echo "$(timestamp): megahit_assembler: paired-ended (2) files: $paired_end_data_2"
	# run assembly based on the libraries available
	if ! [ "$single_end_data" == "no_data" ] && \
	! [ "$paired_end_data_1" == "no_data" ] && \
	! [ "$paired_end_data_1" == "no_data" ]; then 
		echo "$(timestamp): megahit_assembler: assembling with both paired-ended and single-ended data"
		megahit \
			-1 $paired_end_data_1 \
			-2 $paired_end_data_2 \
			-r $single_end_data \
			-t $num_cores \
			-o ${output_dir}
	elif ! [ "$single_end_data" == "no_data" ] && \
	[ "$paired_end_data_1" == "no_data" ] && \
	[ "$paired_end_data_1" == "no_data" ]; then 
		echo "$(timestamp): megahit_assembler: assembling with single-ended data"
		megahit \
			-r $single_end_data \
			-t $num_cores \
			-o ${output_dir}
	elif [ "$single_end_data" == "no_data" ] && \
	! [ "$paired_end_data_1" == "no_data" ] && \
	! [ "$paired_end_data_1" == "no_data" ]; then 
		echo "$(timestamp): megahit_assembler: assembling with paired-ended data"
		megahit \
			-1 $paired_end_data_1 \
			-2 $paired_end_data_2 \
			-t $num_cores \
			-o ${output_dir}
	else
		echo "$(timestamp): megahit_assembler: libraries provided are not suitible for multiple-library assembly"
		exit 1
	fi
}
