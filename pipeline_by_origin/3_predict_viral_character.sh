#!/bin/bash
###############################################################################
#       Aydin Karatas
#		Project Coprolite Viromes
#		3_predict_viral_character.sh 
###############################################################################
cd $HOME/project_coprolite_viromes


origin=$1
origin_parent=$2
num_cores=$3 

# predict phage contigs and their lifestyle, family, and hosts
. phabox_predictions/phage_predictions.sh "$origin" "$origin_parent" "$num_cores"

# annotate phages for bacterial genes
. prokka_annotations/bacterial_annot_phage.sh "$origin" "$origin_parent" "$num_cores"
