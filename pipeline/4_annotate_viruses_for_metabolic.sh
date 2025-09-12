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

# create a new contigs file that contains only viral and/or phage contigs
# . prokka_annotations/create_viral_phage_contigs.sh "$origin" "$origin_parent" "$num_cores"

# calculate number of viral contigs by PROKKA vs phage contigs by PhaBOX
# . data_wrangling/get_viral_vs_phage_prop.sh "$origin" "$origin_parent" "$num_cores"

# annotate viral/phage contigs for bacterial genes
# . prokka_annotations/bacterial_annot_virus_and_phage.sh "$origin" "$origin_parent" "$num_cores"
. prokka_annotations/bacterial_annot_phage.sh "$origin" "$origin_parent" "$num_cores"
