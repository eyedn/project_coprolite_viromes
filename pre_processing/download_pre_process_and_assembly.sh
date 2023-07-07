###############################################################################
#       Aydin Karatas
#		Project Coprolite Viromes
#		download_pre_process_and_assembly.sh 
###############################################################################
#!/bin/bash


origin=$1
origin_parent=$2
num_cores=$3

# call download and pre-processing script
. $HOME/project_coprolite_viromes/pre_processing/download_and_pre_process.sh "$origin" "$origin_parent" "$num_cores"

# call assembly script
. $HOME/project_coprolite_viromes/megahit_assembly/assembly.sh "$origin" "$origin_parent" "$num_cores"
