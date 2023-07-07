###############################################################################
#       Aydin Karatas
#		Project Coprolite Viromes
#		extract_directories.sh 
###############################################################################
#!/bin/bash
# qsub -cwd -N extract_<o> -o $HOME/joblogs/compress/ -j y -l h_rt=5:00:00,h_data=4G -M $USER@mail -m ea compress_directory.sh <o> <p> <d> <true/false>

origin=$1
origin_parent=$2
directory_name=$3
include_trailing_asterisk=$4

# Combine all the folders for the given origin into a new master folder
mkdir $origin_parent/${origin}_${directory_name}
if [[ $include_trailing_asterisk == true ]]; then
    mv $origin_parent/${origin}/*/*/${directory_name}*/* \
        $origin_parent/${origin}_${directory_name}
else
    mv $origin_parent/${origin}/*/*/${directory_name}/* \
        $origin_parent/${origin}_${directory_name}
fi