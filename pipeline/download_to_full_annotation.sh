###############################################################################
#       Aydin Karatas
#		Project Coprolite Viromes
#		download_to_full_annotation.sh 
###############################################################################
#!/bin/bash
cd $HOME/project_coprolite_viromes


origin=$1
origin_parent=$2
num_cores=$3

# call download and pre-processing script
. download/download.sh "$origin" "$origin_parent" "$num_cores"

# call assembly script
. megahit_assembly/assembly.sh "$origin" "$origin_parent" "$num_cores"

# annotate all contigs for viral genes
. prokka_annotations/viral_annotation.sh "$origin" "$origin_parent" "$num_cores"

# create a new contigs file that contains only contigs that had a viral annotation
. prokka_annotations/create_viral_contigs.sh "$origin" "$origin_parent" "$num_cores"

# annotate viral contigs for bacterial genes
. prokka_annotations/bacterial_annot_prokka.sh "$origin" "$origin_parent" "$num_cores"
