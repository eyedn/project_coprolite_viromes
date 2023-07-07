###############################################################################
#       Aydin Karatas
#		Project Coprolite Viromes
#		annotate_contigs.sh 
###############################################################################
#!/bin/bash
source $HOME/project_coprolite_viromes/general_bash_functions/timestamp.sh
source /u/local/Modules/default/init/modules.sh
module load anaconda3
conda activate myconda


# contains the prokka command that annotated the contigs file 
prokka_annotator() {
	local sample=$1
	local contigs_file=$2
	local custom_db=$3
	local annot_dir=$4
	local type=$5
	local label=$6
	local num_cores=$7

	echo "$(timestamp): prokka_annotator: annotating genes for $type"
	echo "$(timestamp): prokka_annotator: contigs file: $contigs_file"
	echo "$(timestamp): prokka_annotator: custom database: $custom_db"

	# annotate with prokka
	if ! [ "$custom_db" == "no_data" ]; then
		prokka \
			--proteins $custom_db \
			--outdir $annot_dir \
			--prefix $sample \
			--kingdom $type \
			--fast \
			--metagenome \
			--cpus $num_cores \
			$contigs_file
	else
		prokka \
			--outdir $annot_dir \
			--prefix $sample \
			--kingdom $type \
			--fast \
			--metagenome \
			--cpus $num_cores \
			$contigs_file
	fi
}
