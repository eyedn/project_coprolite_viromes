#!/bin/bash
###############################################################################
#       Aydin Karatas
#		Project Coprolite Viromes
#		phage_predictions.sh 
###############################################################################
cd $HOME/project_coprolite_viromes
for FILE in phabox_predictions/bash_functions/* ; do source $FILE ; done
for FILE in general_bash_functions/* ; do source $FILE ; done
source /u/local/Modules/default/init/modules.sh
module load anaconda3
conda activate phabox


# define inputs variables
origin=$1
project_dir=$2
num_cores=$3

# define sample variables
sample=$(head -n ${SGE_TASK_ID} ${project_dir}/samples/${origin}_samples.txt | \
		tail -n 1 | cut -d ' ' -f 1)


# define directories and files
contigs_dir="${project_dir}/contigs"
assembly_dir="${contigs_dir}/${origin}_${sample}_assembly"
predict_dir="${project_dir}/phage_predictions/${origin}_${sample}_prediction"
contigs_file="${assembly_dir}/${origin}_${sample}_all_contigs.fa"
phage_file="${predict_dir}/predicted_phage.fa"

# check if predictions already was complete for this sample
if ls $predict_dir/${sample}_DONE.txt 1> /dev/null 2>&1; then
	echo "$(timestamp): phage_predictions: $predict_dir/${sample}_DONE.txt found."
	return 0
fi

# check if contigs file exists
if ls ${contigs_file}* 1> /dev/null 2>&1; then
	echo "$(timestamp): phage_predictions: contigs file found"
else
	echo "$(timestamp): phage_predictions: contigs file not found"
	rmdir $annot_dir
	exit 1
fi

# uses PhaBOX tools for phage prediction and analysis
echo "===================================================================================================="
echo "$(timestamp): phage_predictions: $origin; $sample"
echo "===================================================================================================="
# identify contigs that are phages
get_phages "$sample" "$contigs_file" "$predict_dir" "$num_cores"
# identify is phages are virulent or temperate
get_lifestyles "$sample" "$phage_file" "$predict_dir" "$num_cores"
# identify taxonomic classification of phages
get_families "$sample" "$phage_file" "$predict_dir" "$num_cores"
# identify hosts of phages
get_hosts "$sample" "$phage_file" "$predict_dir" "$num_cores"

# compress files
echo "$(timestamp): phage_predictions: compressing extra files from phage predictions of $sample"

# Check if the directories exist before attempting to create compressed archives
if [ -d "$predict_dir/midfolder" ]; then
	echo "$(timestamp): phage_predictions: compressing 'midfolder' from phage predictions of $sample"
	gzip $predict_dir/*
	cd "$predict_dir"
	tar -czvf midfolder.tar.gz midfolder
	rm -r midfolder
else
	echo "Error: Directory 'midfolder' not found. Skipping compression."
fi

if [ -d "$predict_dir/CNN_temp" ]; then
	echo "$(timestamp): phage_predictions: compressing 'CNN_temp' from phage predictions of $sample"
	tar -czvf CNN_temp.tar.gz CNN_temp
	rm -r CNN_temp
else
	echo "Error: Directory 'CNN_temp' not found. Skipping compression."
fi

cd "$HOME/project_coprolite_viromes"
touch $predict_dir/${sample}_DONE.txt