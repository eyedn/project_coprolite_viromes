#!/bin/bash
###############################################################################
#       Aydin Karatas
#       Project Coprolite Viromes
#       get_families.sh
###############################################################################
# Predict viral taxonomy, including family assignments, with PhaBOX PhaGCN.
get_families() {
    local sample=$1
    local contigs_file=$2
    local predict_dir=$3
    local num_cores=$4
    local input_file="${contigs_file}"
    local temporary_fasta=""
    local previous_dir

    # Reuse a completed PhaGCN taxonomy table.
    if [ -s "$predict_dir/out/phagcn_prediction.csv" ]; then
        echo "$(timestamp): get_families: predictions already completed"
        return 0
    fi

    # Create the PhaGCN output directory.
    mkdir -p "$predict_dir"

    # Prepare a temporary readable FASTA when the canonical input is gzipped.
    if [ -f "${contigs_file}" ] && [[ "${contigs_file}" == *.gz ]]; then
        temporary_fasta=$(mktemp "${predict_dir}/.phagcn_input.XXXXXX.fa")
        gzip -cd "${contigs_file}" > "${temporary_fasta}"
        input_file="${temporary_fasta}"
    elif [ ! -f "${contigs_file}" ] && [ -f "${contigs_file}.gz" ]; then
        temporary_fasta=$(mktemp "${predict_dir}/.phagcn_input.XXXXXX.fa")
        gzip -cd "${contigs_file}.gz" > "${temporary_fasta}"
        input_file="${temporary_fasta}"
    elif [ ! -f "${contigs_file}" ]; then
        echo "$(timestamp): get_families: ERROR! contigs file not found"
        return 1
    fi

    echo "$(timestamp): get_families: $sample"
    echo "__________________________________________________"
    # Run PhaGCN with the core count requested by the submitting job.
    previous_dir=$(pwd)
    cd "$phabox"
    if ! python3 PhaGCN_single.py \
        --contigs "$input_file" \
        --threads "$num_cores" \
        --len 100 \
        --rootpth "$predict_dir"
    then
        cd "$previous_dir"
        [ -z "$temporary_fasta" ] || rm -f "$temporary_fasta"
        return 1
    fi
    cd "$previous_dir"
    [ -z "$temporary_fasta" ] || rm -f "$temporary_fasta"
    echo "__________________________________________________"

    # Require a nonempty PhaGCN prediction table before returning.
    if ls $predict_dir/out/phagcn_prediction.csv 1> /dev/null 2>&1; then
        echo "$(timestamp): get_families: taxonomic predictions file created"
        # Reject an empty output table as an incomplete prediction.
        if ! [ -s "$predict_dir/out/phagcn_prediction.csv" ]; then
            echo "$(timestamp): get_families: ERROR!" \
                "taxonomic predictions file is empty"
            exit 1
        fi
    else
        echo "$(timestamp): get_families: ERROR!" \
            "taxonomic predictions file not found"
        exit 1
    fi
}
