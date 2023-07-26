###############################################################################
#       Aydin Karatas
#		Project Coprolite Viromes
#		predict_lifestyle.sh 
###############################################################################
#!/bin/bash
cd $HOME/project_coprolite_viromes
for FILE in phatyp_lifestyle_prediction/bash_functions/* ; do source $FILE ; done
for FILE in general_bash_functions/* ; do source $FILE ; done


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
lifestyle_dir="${project_dir}/lifestyle"
predict_dir="${lifestyle_dir}/${origin}_${sample}_prediction"
contigs_file="${assembly_dir}/${origin}_${sample}_viral_contigs.fa"

# check if contigs file exists
if ls $contigs_file 1> /dev/null 2>&1; then
	echo "$(timestamp): predict_lifestyle: contigs file found"
else
	echo "$(timestamp): predict_lifestyle: contigs file not found"
	rmdir $annot_dir
	exit 1
fi

# check if predictions already completed
if ls $predict_dir/out/phatyp_prediction.csv 1> /dev/null 2>&1; then
	echo "$(timestamp): predict_lifestyle: predictions already completed"
	return 0
fi

# annotation function uses prokka
echo "===================================================================================================="
echo "$(timestamp): predict_lifestyle: $origin; $sample"
echo "===================================================================================================="
get_lifestyles "$sample" "$contigs_file" "$predict_dir" "$num_cores"

# compress annotation files
echo "$(timestamp): predict_lifestyle: compressing extra files from assembly of $sample"
cd $predict_dir
gzip *.fa
tar -czvf midfolder.tar.gz midfolder
cd $HOME/project_coprolite_viromes
