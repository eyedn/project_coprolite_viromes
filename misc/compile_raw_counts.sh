###############################################################################
#       Aydin Karatas
#		Project Coprolite Viromes
#		compile_raw_counts.sh 
###############################################################################
#!/bin/bash

# source hoffman2 modules
. /u/local/Modules/default/init/modules.sh
module load python
. $HOME/my_py/bin/activate
raw_counts_dir=$1
output_path=$2

# collect raw counts from the given directory
python3 $HOME/project_coprolite_viromes/data_wrangling/compile_raw_counts.py \
    $raw_counts_dir $output_path