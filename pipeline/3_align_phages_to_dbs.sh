#!/bin/bash
###############################################################################
#       Aydin Karatas
#		Project Coprolite Viromes
#		3_align_phages_to_dbs.sh 
###############################################################################
cd $HOME/project_coprolite_viromes


origin=$1
origin_parent=$2
num_cores=$3 

# align phages to vfdb
. hmm_alignment/vf_alignment.sh "$origin" "$origin_parent" "$num_cores" 

# align phages to cazy db
# . hmm_alignment/cazy_alignment.sh "$origin" "$origin_parent" "$num_cores" 
