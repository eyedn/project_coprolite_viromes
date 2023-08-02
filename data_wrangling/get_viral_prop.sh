###############################################################################
#       Aydin Karatas
#		Project Coprolite Viromes
#		get_viral_prop.sh 
###############################################################################
#!/bin/bash
cd $HOME/project_coprolite_viromes
for FILE in general_bash_functions/* ; do source $FILE ; done
source /u/local/Modules/default/init/modules.sh
module load python
source $python_env


# define inputs variables
origin=$1
project_dir=$2
num_cores=$3

# define directories and file
contigs_dir="${project_dir}/contigs"
prokka_annotations="${project_dir}/genome_annotation"
data_dir="$project_dir/data"
annot_search_dir="$prokka_annotations/*viral"
gff_list="$data_dir/viral_prop_tmp.txt"
csv_path="$data_dir/viral_prop.csv"

# create a list of all files to generate counts from
ls $contigs_dir/*/*phage_contigs.fa.gz > $fa_list
echo "$(timestamp): get_viral_prop: generated file of all contig paths needed"
echo "$(timestamp): get_viral_prop: using the following contig files:"
cat $fa_list

ls $search_dir/*gff.gz > $gff_list
echo "$(timestamp): get_viral_prop: generated file of all gff paths needed"
echo "$(timestamp): get_viral_prop: using the following gff files:"
cat $gff_list

# generate counts with python script
echo "===================================================================================================="
echo "$(timestamp): get_viral_prop: generating bacterial gene counts"
echo "===================================================================================================="
python3 data_wrangling/get_viral_prop.py \
	$fa_list \
	$gff_list \
	$csv_path
rm $gff_list

# check if raw counts was created
if ls $csv_path 1> /dev/null 2>&1; then
	echo "$(timestamp): get_viral_prop: viral prop csv created"
else
	echo "$(timestamp): get_viral_prop: viral prop csv not found"
	exit 1
fi
