#!/bin/bash
###############################################################################
#       Aydin Karatas
#       Project Coprolite Viromes
#       get_lifestyles.sh
###############################################################################
# Predict viral lifestyles with PhaBOX PhaTYP.
get_lifestyles() {
    local sample=$1
    local contigs_file=$2
    local predict_dir=$3
    local num_cores=$4
    local input_file="${contigs_file}"
    local temporary_fasta=""
    local previous_dir


    # Reuse a completed PhaTYP prediction table.
    if [ -s "$predict_dir/out/phatyp_prediction.csv" ]; then
        echo "$(timestamp): get_lifestyles: predictions already completed"
        return 0
    fi

    # Create the PhaTYP output directory.
    mkdir -p "$predict_dir"

    # Prepare a temporary readable FASTA when the canonical input is gzipped.
    if [ -f "${contigs_file}" ] && [[ "${contigs_file}" == *.gz ]]; then
        temporary_fasta=$(mktemp "${predict_dir}/.phatyp_input.XXXXXX.fa")
        gzip -cd "${contigs_file}" > "${temporary_fasta}"
        input_file="${temporary_fasta}"
    elif [ ! -f "${contigs_file}" ] && [ -f "${contigs_file}.gz" ]; then
        temporary_fasta=$(mktemp "${predict_dir}/.phatyp_input.XXXXXX.fa")
        gzip -cd "${contigs_file}.gz" > "${temporary_fasta}"
        input_file="${temporary_fasta}"
    elif [ ! -f "${contigs_file}" ]; then
        echo "$(timestamp): get_lifestyles: ERROR! contigs file not found"
        return 1
    fi

    echo "$(timestamp): get_lifestyles: $sample"
    echo "__________________________________________________"
    # Run PhaTYP with the core count requested by the submitting job.
    previous_dir=$(pwd)
    cd "$phabox"
    if ! python3 PhaTYP_single.py \
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

    # Require a nonempty PhaTYP prediction table before returning.
    if ls $predict_dir/out/phatyp_prediction.csv 1> /dev/null 2>&1; then
        echo "$(timestamp): get_lifestyles: lifestyle predictions file created"
        # Reject an empty output table as an incomplete prediction.
        if ! [ -s "$predict_dir/out/phatyp_prediction.csv" ]; then
            echo "$(timestamp): get_lifestyles: ERROR!" \
                "lifestyle predictions file is empty"
            exit 1
        fi
    else
        echo "$(timestamp): get_lifestyles: ERROR!" \
            "lifestyle predictions file not found"
        exit 1
    fi
}
