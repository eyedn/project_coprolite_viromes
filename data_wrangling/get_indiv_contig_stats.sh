###############################################################################
#       Aydin Karatas
#		Project Coprolite Viromes
#		get_indiv_contig_stats.sh 
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

# define sample variable
sample=$(head -n ${SGE_TASK_ID} ${project_dir}/samples/${origin}_samples.txt | \
		tail -n 1 | cut -d ' ' -f 1)

# define directories and file
contigs_dir="${project_dir}/contigs"
data_dir="$project_dir/data/indiv_contig_stats"
stats_file="$contigs_dir/${origin}_${sample}_assembly/${origin}_${sample}_log.txt"
csv_path="$data_dir/${origin}_${sample}_contig_stats.csv"

# check if assembly was already complete for this sample
if ls $csv_path 1> /dev/null 2>&1; then
	echo "$(timestamp): get_indiv_contig_stats: final contigs file already created"
	return 0
fi

# check if download was already complete for this sample
if ls $stats_file 1> /dev/null 2>&1; then
	echo "$(timestamp): get_indiv_contig_stats: stats file found"
else
	echo "$(timestamp): get_indiv_contig_stats: stats file not found"
	exit 1
fi

# generate counts with python script
echo "===================================================================================================="
echo "$(timestamp): get_indiv_contig_stats: generating stats"
echo "===================================================================================================="
mkdir -p $data_dir
head -n 5 $stats_file | tail -n 1 > $data_dir/${origin}_${sample}_contig_stats_tmp.txt
tail -n 2 $stats_file | head -n 1 >> $data_dir/${origin}_${sample}_contig_stats_tmp.txt
python3 data_wrangling/get_indiv_contig_stats.py \
	$data_dir/${origin}_${sample}_contig_stats_tmp.txt \
	$csv_path
rm $data_dir/${origin}_${sample}_contig_stats_tmp.txt

# check if raw counts was created
if ls $csv_path 1> /dev/null 2>&1; then
	echo "$(timestamp): get_indiv_contig_stats: viral prop csv created"
else
	echo "$(timestamp): get_indiv_contig_stats: viral prop csv not found"
	exit 1
fi
