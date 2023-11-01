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
incE="1e-3"

# build hmm files for alignment
. hmm_alignment/build_hmm_file.sh "$origin" "$origin_parent" "$num_cores"

# align phages to vfdb
. hmm_alignment/vf_alignment.sh "$origin" "$origin_parent" "$num_cores" "$incE"
