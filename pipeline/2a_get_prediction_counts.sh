#!/bin/bash
###############################################################################
#       Aydin Karatas
#       Project Coprolite Viromes
#       2a_get_prediction_counts.sh
###############################################################################


cd $HOME/project_coprolite_viromes


origin=$1
origin_parent=$2
num_cores=$3

# . pipeline/2a_supplement/2b_1_get_counts_hosts.sh "$origin" "$origin_parent" "$num_cores"
# . pipeline/2a_supplement/2b_2_get_counts_phage_ec.sh "$origin" "$origin_parent" "$num_cores"
. pipeline/2a_supplement/2b_3_get_counts_viral_lifestyle.sh "$origin" "$origin_parent" "$num_cores"
# . pipeline/2a_supplement/2b_4_get_counts_viral_taxonomy.sh "$origin" "$origin_parent" "$num_cores"
. pipeline/2a_supplement/2b_5_get_counts_bac_ec.sh "$origin" "$origin_parent" "$num_cores"
. pipeline/2a_supplement/2b_6_get_counts_vir_ec.sh "$origin" "$origin_parent" "$num_cores"
