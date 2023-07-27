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

# predict phage contigs and their lifestyle, family, and hosts
. phatyp_predictions/phage_predictions.sh "$origin" "$origin_parent" "$num_cores"

# annotate phages for bacterial genes
. prokka_annotations/bacterial_annotation.sh "$origin" "$origin_parent" "$num_cores"
