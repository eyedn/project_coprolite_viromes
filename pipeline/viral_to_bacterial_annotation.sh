###############################################################################
#       Aydin Karatas
#		Project Coprolite Viromes
#		viral_to_bacterial_annotation.sh 
###############################################################################
#!/bin/bash
cd $HOME/project_coprolite_viromes


origin=$1
origin_parent=$2
num_cores=$3 

# annotate all contigs for viral genes
. prokka_annotations/viral_annotation.sh "$origin" "$origin_parent" "$num_cores"

# create a new contigs file that contains only contigs that had a viral annotation
. prokka_annotations/create_viral_contigs.sh "$origin" "$origin_parent" "$num_cores"

# annotate viral contigs for bacterial genes
. prokka_annotations/bacterial_annot_prokka.sh "$origin" "$origin_parent" "$num_cores"
