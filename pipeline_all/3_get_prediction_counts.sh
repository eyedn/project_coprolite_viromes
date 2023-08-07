###############################################################################
#       Aydin Karatas
#		Project Coprolite Viromes
#		3_get_prediction_counts.sh 
###############################################################################
#!/bin/bash
cd $HOME/project_coprolite_viromes


origin=$1
origin_parent=$2
num_cores=$3

# run after pipeline_indiv/1_download_and_assembly.sh ran
. pipeline_all/3_get_counts_hosts.sh "$origin" "$origin_parent" "$num_cores"
. pipeline_all/3_get_counts_phage_ec.sh "$origin" "$origin_parent" "$num_cores"
. pipeline_all/3_get_counts_viral_lifestyle.sh "$origin" "$origin_parent" "$num_cores"
. pipeline_all/3_get_counts_viral_taxonomy.sh "$origin" "$origin_parent" "$num_cores"
