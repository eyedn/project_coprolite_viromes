###############################################################################
#       Aydin Karatas
#		Project Coprolite Viromes
#		download_to_assembly.sh 
###############################################################################
#!/bin/bash
cd $home_dir

origin=$1
origin_parent=$2
num_cores=$3

# call download and pre-processing script
. download/download.sh "$origin" "$origin_parent" "$num_cores"

# call assembly script
. megahit_assembly/assembly.sh "$origin" "$origin_parent" "$num_cores"
