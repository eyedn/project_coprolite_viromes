###############################################################################
#       Aydin Karatas
#		Project Coprolite Viromes
#		2_annotate_all_for_viruses.sh 
###############################################################################
#!/bin/bash
cd $HOME
source .bashrc
cd $HOME/project_coprolite_viromes


origin=$1
origin_parent=$2
num_cores=$3 

# annotate all contigs for viral genes
. prokka_annotations/viral_annotation.sh "$origin" "$origin_parent" "$num_cores"

# get viral contig proportions
. data_wrangling/get_indiv_viral_prop.sh "$origin" "$origin_parent" "$num_cores"
