###############################################################################
#       Aydin Karatas
#		Project Coprolite Viromes
#		sample_counts.sh 
###############################################################################
#!/bin/bash

# source hoffman2 modules and bash functions
. $HOME/project_coprolite_viromes/general_functions.sh
. $HOME/project_coprolite_viromes/data_wrangling/data_wrangling_funuctions.sh
. /u/local/Modules/default/init/modules.sh
module load python
. $HOME/my_py/bin/activate
origin=$1
origin_parent=$2
sample=$(head -n ${SGE_TASK_ID} ${origin_parent}/${origin}/samples.txt | \
		tail -n 1 | cut -d , -f 1)
sample_path="${origin_parent}/${origin}/${sample}"
list_of_ids="${sample_path}/acc_ids.txt"

# create observation counts directories for this samples
if ! [ -d "$sample_path/Bacteria_ec_data" ];then
    mkdir $sample_path/Bacteria_ec_data
fi
if ! [ -d "$sample_path/Viruses_ec_data" ];then
    mkdir $sample_path/Viruses_ec_data
fi
if ! [ -d "$sample_path/Bacteria_gene_data" ];then
    mkdir $sample_path/Bacteria_gene_data
fi
if ! [ -d "$sample_path/Viruses_gene_data" ];then
    mkdir $sample_path/Viruses_gene_data
fi

# create observation counts directories for all samples
if ! [ -d "$SCRATCH/project_coprolite_viromes/Bacteria_ec_data" ];then
    mkdir $SCRATCH/project_coprolite_viromes/Bacteria_ec_data
fi
if ! [ -d "$SCRATCH/project_coprolite_viromes/Viruses_ec_data" ];then
    mkdir $SCRATCH/project_coprolite_viromes/Viruses_ec_data
fi
if ! [ -d "$SCRATCH/project_coprolite_viromes/Bacteria_gene_data" ];then
    mkdir $SCRATCH/project_coprolite_viromes/Bacteria_gene_data
fi
if ! [ -d "$SCRATCH/project_coprolite_viromes/Viruses_gene_data" ];then
    mkdir $SCRATCH/project_coprolite_viromes/Viruses_gene_data
fi

# collect ec and gene counts and CPM for viral and bacterial annotations
while read -r id; do
	echo "=================================================="
	echo "$(timestamp): viral gene and ec counts"
	echo -e "\torigin: $origin"
	echo -e "\tsample: $sample"
    echo -e "\tid: $id"
	echo "=================================================="
	run_specific_counts $id "$sample_path/$id" "Viruses"

    echo "=================================================="
	echo "$(timestamp): bacterial gene and ec counts"
	echo -e "\torigin: $origin"
	echo -e "\tsample: $sample"
    echo -e "\tid: $id"
	echo "=================================================="
    run_specific_counts $id "$sample_path/$id" "Bacteria"
done < "$list_of_ids"

# collect all counts together
echo "=================================================="
echo "$(timestamp): gatherng counts together"
echo -e "\torigin: $origin"
echo -e "\tsample: $sample"
echo "=================================================="
collect_counts $sample_path "ec" "Viruses" $origin $sample
collect_counts $sample_path "gene" "Viruses" $origin $sample
collect_counts $sample_path "ec" "Bacteria" $origin $sample
collect_counts $sample_path "gene" "Bacteria" $origin $sample