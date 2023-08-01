###############################################################################
#       Aydin Karatas
#		Project Coprolite Viromes
#		main.sh 
###############################################################################
#!/bin/bash
cd $HOME/project_coprolite_viromes


origin=$1
origin_parent=$2
num_cores=$3

# predict phage contigs and their lifestyle, family, and hosts
. phatyp_predictions/bacterial_annot_all.sh "$origin" "$origin_parent" "$num_cores"
