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

# create lifestyle predictions of viral contigs
. phatyp_lifestyle_prediction/predict_lifestyle.sh "$origin" "$origin_parent" "$num_cores"
