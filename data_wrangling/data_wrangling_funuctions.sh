###############################################################################
#       Aydin Karatas
#		Project Coprolite Viromes
#		annotation_functions.sh 
###############################################################################
#!/bin/bash
. $HOME/project_coprolite_viromes/general_functions.sh

# generate gene and ec counts given an id and type
function run_specific_counts() {
    local id=$1
    local id_path=$2
    local type=$3
    local origin=$4
    local sample=$5

    # uncompress data
    gunzip ${id_path}/${type}_annotation/${id}.tsv.gz
    # fun raw counts
    python3 $HOME/project_coprolite_viromes/data_wrangling/run_specific_counts.py \
        ${id_path}/${type}_annotation/${id}.tsv \
        ${id_path}/../${type}_gene_data/${type}_${id}_gene.csv \
        ${id_path}/../${type}_ec_data/${type}_${id}_ec.csv
    # compress data
    gzip ${id_path}/${type}_annotation/${id}.tsv
}

# collect all the sample counts into one master counts file
function collect_counts() {
    local sample_path=$1
    local count_type=$2
    local type=$3

    # combine directory of indiv. run counts
    python3 $HOME/project_coprolite_viromes/data_wrangling/collect_sample_counts.py \
        ${sample_path}/${type}_${count_type}_data \
        $SCRATCH/project_coprolite_viromes/${type}_${count_type}_data/${origin}_${sample}_${type}.csv
}