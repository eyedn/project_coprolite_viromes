#!/usr/bin/env bash
###############################################################################
#       Aydin Karatas
#       Project Coprolite Viromes
#       vf_alignment.sh
###############################################################################


code_dir="${VIROME_CODE_DIR:-$HOME/project_coprolite_viromes}"
source "$code_dir/general_bash_functions/slurm.sh"
validate_cpus "${3:-}" || exit 2


cd "${VIROME_CODE_DIR:-$HOME/project_coprolite_viromes}" || return 1
for file_path in hmm_alignment/bash_functions/*; do
    source "$file_path"
done
for file_path in general_bash_functions/*; do
    source "$file_path"
done


activate_environment python || return 1

# define input variables.
origin=$1
project_dir=$2
num_cores=$3

# define sample variables.
sample_record=$(select_record \
    "${project_dir}/samples/${origin}_samples.txt") || exit 2
read -r sample accession_ids <<< "$sample_record"
label="bac_on_phage"

# define directories and files.
alignment_dir="${project_dir}/alignment"
annotations_dir="${project_dir}/genome_annotation/\
${origin}_${sample}_annotation_${label}"
prediction_dir="${project_dir}/phage_predictions/\
${origin}_${sample}_prediction/out"
orfs_file="${annotations_dir}/${sample}.faa"
phamer_file="${prediction_dir}/phamer_prediction.csv"


# return 0 for a nonempty FASTA, 10 for zero records, and 1 for malformed data.
check_faa_stream() {
    awk '
        BEGIN { records = 0; invalid = 0 }
        /^[[:space:]]*$/ { next }
        /^>/ {
            header = substr($0, 2)
            gsub(/^[[:space:]]+|[[:space:]]+$/, "", header)
            if (header == "") {
                invalid = 1
            }
            records++
            next
        }
        {
            if (records == 0) {
                invalid = 1
            }
        }
        END {
            if (invalid) {
                exit 1
            }
            if (records == 0) {
                exit 10
            }
        }
    '
}


# return 0 only when a valid PhaMer table contains all non-phage predictions.
check_all_non_phage() {
    local phamer_path=$1

    awk -F ',' '
        function clean(value) {
            sub(/\r$/, "", value)
            gsub(/^[[:space:]]+|[[:space:]]+$/, "", value)
            gsub(/^"|"$/, "", value)
            return value
        }
        NR == 1 {
            for (field = 1; field <= NF; field++) {
                if (clean($field) == "Pred") {
                    pred_column = field
                    pred_columns++
                }
                if (clean($field) == "Accession") {
                    accession_column = field
                    accession_columns++
                }
            }
            if (pred_columns != 1 || accession_columns != 1) {
                invalid = 1
            }
            next
        }
        /^[[:space:]]*$/ { next }
        {
            if (invalid) {
                next
            }
            prediction = tolower(clean($pred_column))
            accession = clean($accession_column)
            if (accession == "" || \
                    (prediction != "phage" && prediction != "non-phage")) {
                invalid = 1
                next
            }
            rows++
            if (prediction == "phage") {
                has_phage = 1
            }
        }
        END {
            if (invalid || rows == 0) {
                exit 1
            }
            if (has_phage) {
                exit 10
            }
        }
    ' "$phamer_path"
}


# validate VF-specific empty inputs before calling the generic aligner.
faa_status=1
if [ -f "${orfs_file}" ]; then
    if check_faa_stream < "${orfs_file}"; then
        faa_status=0
    else
        faa_status=$?
    fi
elif [ -f "${orfs_file}.gz" ]; then
    if ! gzip -t "${orfs_file}.gz" 2>/dev/null; then
        echo "$(timestamp): vf_alignment: ERROR! corrupt FAA gzip: \
${orfs_file}.gz" >&2
        return 1
    fi
    if gzip -cd "${orfs_file}.gz" | check_faa_stream; then
        faa_status=0
    else
        faa_status=$?
    fi
else
    if [ ! -s "${phamer_file}" ]; then
        echo "$(timestamp): vf_alignment: ERROR! FAA not found and PhaMer \
table is missing: ${orfs_file}" >&2
        return 1
    fi
    if check_all_non_phage "${phamer_file}"; then
        echo "$(timestamp): vf_alignment: QC exclusion \
sample=${origin}_${sample} \
reason=no_phage_predictions"
        return 0
    else
        phamer_status=$?
    fi
    if [ "${phamer_status}" -eq 1 ]; then
        echo "$(timestamp): vf_alignment: ERROR! malformed PhaMer table: \
${phamer_file}" >&2
    else
        echo "$(timestamp): vf_alignment: ERROR! FAA not found for sample with \
phage predictions: ${orfs_file}" >&2
    fi
    return 1
fi

if [ "${faa_status}" -eq 10 ]; then
    echo "$(timestamp): vf_alignment: QC exclusion sample=${origin}_${sample} \
reason=zero_faa_records"
    return 0
fi
if [ "${faa_status}" -ne 0 ]; then
    echo "$(timestamp): vf_alignment: ERROR! malformed FAA: ${orfs_file}" >&2
    return 1
fi


# search each reference independently against the complete bacterial FAA.
for version in VFDB_setA VFDB_setB; do
    case "$version" in
        VFDB_setA) db_file="${ref_db}/VFDB_setA_pro_20230917.txt" ;;
        VFDB_setB) db_file="${ref_db}/VFDB_setB_pro_20260923.txt" ;;
    esac
    sample_alignment_output="${alignment_dir}/vfdb_all_orfs/${version}/\
${origin}_${sample}_vf"
    python3 data_wrangling/search_vfdb.py \
        "$orfs_file" "${annotations_dir}/${sample}.gff" \
        "$db_file" "$sample_alignment_output" "$version" \
        "$num_cores" "$hmmsearch" || return 1
done
