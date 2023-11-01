#!/bin/bash
###############################################################################
#       Aydin Karatas
#		Project Coprolite Viromes
#		4_annotate_viruses_for_metabolic.sh 
###############################################################################
cd $HOME/project_coprolite_viromes


origin=$1
origin_parent=$2
num_cores=$3 
vf_incE="1e-3"
cazy_incE="1e-5"

# align phages to vfdb
. hmm_alignment/vf_alignment.sh "$origin" "$origin_parent" "$num_cores" "$vf_incE"

# align phages to cazy db
. hmm_alignment/cazy_alignment.sh "$origin" "$origin_parent" "$num_cores" "$cazy_incE"
