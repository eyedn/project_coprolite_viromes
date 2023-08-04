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
. data_wrangling/get_indiv_contig_stats.sh "$origin" "$origin_parent" "$num_cores"
