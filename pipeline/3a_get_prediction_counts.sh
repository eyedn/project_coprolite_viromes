#!/bin/bash
###############################################################################
#       Aydin Karatas
#		Project Coprolite Viromes
#		3_get_prediction_counts.sh 
###############################################################################
cd $HOME/project_coprolite_viromes


origin=$1
origin_parent=$2
num_cores=$3

# run after pipeline_indiv/1_download_and_assembly.sh rans
. pipeline/3a_supplement/3b_1_get_counts_hosts.sh "$origin" "$origin_parent" "$num_cores"
. pipeline/3a_supplement/3b_2_get_counts_phage_ec.sh "$origin" "$origin_parent" "$num_cores"
. pipeline/3a_supplement/3b_3_get_counts_viral_lifestyle.sh "$origin" "$origin_parent" "$num_cores"
. pipeline/3a_supplement/3b_5_get_counts_bac_ec.sh "$origin" "$origin_parent" "$num_cores"
. pipeline/3a_supplement/3b_6_get_counts_vir_ec.sh "$origin" "$origin_parent" "$num_cores"
