###############################################################################
#       Aydin Karatas
#		Project Coprolite Viromes
#		create_directories.sh 
###############################################################################
#!/bin/bash

# create subdirectories
origin=$1
origin_parent=$2
cd $origin_parent/$origin
# replace tabs and semicolons with commas in the file
sed -i 's/[\t;]/,/g' samples.txt
while read line; do
    # split line by comma and save in array
    array=($(echo $line | tr "," "\n"))

    # create directory with first element of array
    mkdir "${array[0]}"

    # Create new file in the directory with rest of the array
    filename="${array[0]}/acc_ids.txt"
    echo -n "" > "$filename"
    for ((i=1; i<${#array[@]}; i++)); do
        echo "${array[i]}" >> "$filename"
    done
done < $origin_parent/$origin/samples.txt
