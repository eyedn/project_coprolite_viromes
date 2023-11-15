#!/bin/bash
###############################################################################
#       Aydin Karatas
#		Project Coprolite Viromes
#		5_collect_alignment_counts.sh 
###############################################################################
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
prokka_annotations="${project_dir}/genome_annotation"
vf_alignments="${project_dir}/alignment/!vf"
cazy_alignments="${project_dir}/alignment/**cazy"
data_dir="$project_dir/data"
search_dir="$prokka_annotations/!_annotation_phage"

# generate counts with python script
mkdir -p $data_dir
echo "===================================================================================================="
echo "$(timestamp): 5_collect_alignment_counts: collecting alignment counts for vfdb"
echo "===================================================================================================="
python3 data_wrangling/get_alignment_counts.py \
	$vf_alignments \
	$search_dir \
	$data_dir \
	"vf_alignment"

echo "===================================================================================================="
echo "$(timestamp): 5_collect_alignment_counts: collecting alignment counts for cazy"
echo "===================================================================================================="
python3 data_wrangling/get_alignment_counts.py \
	$cazy_alignments \
	$search_dir \
	$data_dir \
	"cazy_alignment"

# check if raw counts was created 
if ls $data_dir/*alignment* 1> /dev/null 2>&1; then
	echo "$(timestamp): ERROR: collect_alignment_counts: alignment files found"
else
	echo "$(timestamp): ERROR: collect_alignment_counts: alignment files NOT found"
	exit 1
fi
