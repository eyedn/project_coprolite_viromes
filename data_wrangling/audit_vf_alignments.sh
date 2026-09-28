#!/usr/bin/env bash

###############################################################################
#           Aydin Loid Karatas
#           Project Coprolite Viromes
#           audit_vf_alignments.sh
###############################################################################

set -euo pipefail

if [ "$#" -ne 3 ]; then
    echo "Usage: audit_vf_alignments.sh PROJECT_DIR QC_OUTPUT \
COMPLETE_SAMPLES_OUTPUT" >&2
    exit 2
fi

project_dir="${1%/}"
qc_output="$2"
complete_samples_output="$3"
alignment_dir="${project_dir}/alignment"
annotation_dir="${project_dir}/genome_annotation"
prediction_dir="${project_dir}/phage_predictions"
temporary_files=()

cleanup() {
    local file_path
    for file_path in "${temporary_files[@]:-}"; do
        if [ -e "${file_path}" ]; then
            rm -f "${file_path}"
        fi
    done
}
trap cleanup EXIT


# Return 0 for a nonempty FASTA, 10 for zero records, and 1 for malformed data.
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


# Return 0 for all-non-phage, 10 for phage-containing, and 1 for malformed.
check_phamer_table() {
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


for required_dir in \
    "${alignment_dir}" \
    "${annotation_dir}" \
    "${prediction_dir}"
do
    if [ ! -d "${required_dir}" ]; then
        echo "audit_vf_alignments: ERROR! missing directory: \
${required_dir}" >&2
        exit 1
    fi
done

qc_parent=$(dirname "${qc_output}")
manifest_parent=$(dirname "${complete_samples_output}")
mkdir -p "${qc_parent}" "${manifest_parent}"

phatyp_samples=$(mktemp "${qc_parent}/.phatyp_samples.XXXXXX")
gff_samples=$(mktemp "${qc_parent}/.gff_samples.XXXXXX")
phamer_samples=$(mktemp "${qc_parent}/.phamer_samples.XXXXXX")
phamer_phage_samples=$(mktemp "${qc_parent}/.phamer_phage_samples.XXXXXX")
non_phage_samples=$(mktemp "${qc_parent}/.non_phage_samples.XXXXXX")
expected_samples=$(mktemp "${qc_parent}/.expected_samples.XXXXXX")
temporary_qc=$(mktemp "${qc_parent}/.$(basename "${qc_output}").XXXXXX")
temporary_manifest=$(
    mktemp "${manifest_parent}/.$(basename "${complete_samples_output}").XXXXXX"
)
temporary_files=(
    "${phatyp_samples}"
    "${gff_samples}"
    "${phamer_samples}"
    "${phamer_phage_samples}"
    "${non_phage_samples}"
    "${expected_samples}"
    "${temporary_qc}"
    "${temporary_manifest}"
)

find "${prediction_dir}" -type f \
    -path '*_prediction/out/phatyp_prediction.csv' \
    -print | while IFS= read -r file_path; do
        sample_directory=$(basename "$(dirname "$(dirname "${file_path}")")")
        printf '%s\n' "${sample_directory%_prediction}"
    done | sort -u > "${phatyp_samples}"

find "${annotation_dir}" -type f \
    -path '*_annotation_bac_on_phage/*.gff.gz' \
    -print | while IFS= read -r file_path; do
        sample_directory=$(basename "$(dirname "${file_path}")")
        printf '%s\n' "${sample_directory%_annotation_bac_on_phage}"
    done | sort -u > "${gff_samples}"

while IFS= read -r file_path; do
    sample_directory=$(basename "$(dirname "$(dirname "${file_path}")")")
    sample_label="${sample_directory%_prediction}"
    printf '%s\n' "${sample_label}" >> "${phamer_samples}"
    if check_phamer_table "${file_path}"; then
        printf '%s\n' "${sample_label}" >> "${non_phage_samples}"
    else
        phamer_status=$?
        if [ "${phamer_status}" -eq 10 ]; then
            printf '%s\n' "${sample_label}" >> "${phamer_phage_samples}"
        else
            echo "audit_vf_alignments: ERROR! malformed PhaMer table: \
${file_path}" >&2
            exit 1
        fi
    fi
done < <(
    find "${prediction_dir}" -type f \
        -path '*_prediction/out/phamer_prediction.csv' -print | sort
)

if [ ! -s "${phamer_samples}" ]; then
    echo "audit_vf_alignments: ERROR! no PhaMer prediction tables found" >&2
    exit 1
fi
if [ -n "$(sort "${phamer_samples}" | uniq -d)" ]; then
    echo "audit_vf_alignments: ERROR! multiple PhaMer tables for a sample" >&2
    sort "${phamer_samples}" | uniq -d >&2
    exit 1
fi
sort -u -o "${phamer_samples}" "${phamer_samples}"
sort -u -o "${phamer_phage_samples}" "${phamer_phage_samples}"
sort -u -o "${non_phage_samples}" "${non_phage_samples}"

if ! cmp -s "${phatyp_samples}" "${gff_samples}"; then
    echo "audit_vf_alignments: ERROR! PhaTYP and GFF sample sets differ" >&2
    comm -3 "${phatyp_samples}" "${gff_samples}" >&2
    exit 1
fi
if ! cmp -s "${phamer_phage_samples}" "${phatyp_samples}"; then
    echo "audit_vf_alignments: ERROR! PhaMer phage and PhaTYP sets differ" >&2
    comm -3 "${phamer_phage_samples}" "${phatyp_samples}" >&2
    exit 1
fi

cat "${phamer_phage_samples}" "${non_phage_samples}" | sort -u \
    > "${expected_samples}"

printf '%s\n' \
    'category,origin,sample_id,sample,status,missing_files' \
    > "${temporary_qc}"

complete_count=0
excluded_count=0
while IFS= read -r sample_label; do
    if [[ ! "${sample_label}" =~ ^([^-]+)-([^_]+)_(.+)$ ]]; then
        echo "audit_vf_alignments: ERROR! invalid sample label: \
${sample_label}" >&2
        exit 1
    fi

    category="${BASH_REMATCH[1]}"
    origin="${BASH_REMATCH[2]}"
    sample_id="${BASH_REMATCH[3]}"
    sample="${category}.${origin}_${sample_id}"
    if [[ "${category}${origin}${sample_id}" == *,* ]]; then
        echo "audit_vf_alignments: ERROR! commas in sample labels" >&2
        exit 1
    fi

    sample_alignment_dir="${alignment_dir}/${sample_label}_vf"
    sample_annotation_dir="${annotation_dir}/\
${sample_label}_annotation_bac_on_phage"
    orfs_file="${sample_annotation_dir}/${sample_id}.faa"
    exclusion_reason=""

    if grep -Fqx "${sample_label}" "${non_phage_samples}"; then
        exclusion_reason="no_phage_predictions"
    else
        faa_status=1
        if [ -f "${orfs_file}" ]; then
            if check_faa_stream < "${orfs_file}"; then
                faa_status=0
            else
                faa_status=$?
            fi
        elif [ -f "${orfs_file}.gz" ]; then
            if ! gzip -t "${orfs_file}.gz" 2>/dev/null; then
                echo "audit_vf_alignments: ERROR! corrupt FAA gzip: \
${orfs_file}.gz" >&2
                exit 1
            fi
            if gzip -cd "${orfs_file}.gz" | check_faa_stream; then
                faa_status=0
            else
                faa_status=$?
            fi
        else
            echo "audit_vf_alignments: ERROR! FAA not found: ${orfs_file}" >&2
            exit 1
        fi

        if [ "${faa_status}" -eq 10 ]; then
            exclusion_reason="zero_faa_records"
        elif [ "${faa_status}" -ne 0 ]; then
            echo "audit_vf_alignments: ERROR! malformed FAA: ${orfs_file}" >&2
            exit 1
        fi
    fi

    missing_files=()
    for required_file in table.txt results.txt; do
        if [ ! -s "${sample_alignment_dir}/${required_file}" ]; then
            missing_files+=("${required_file}")
        fi
    done

    if [ -n "${exclusion_reason}" ]; then
        for stale_file in table.txt results.txt; do
            if [ -e "${sample_alignment_dir}/${stale_file}" ]; then
                echo "audit_vf_alignments: ERROR! excluded sample has stale \
output: ${sample_alignment_dir}/${stale_file}" >&2
                exit 1
            fi
        done
        status="excluded"
    elif [ "${#missing_files[@]}" -gt 0 ]; then
        exclusion_reason="incomplete_alignment"
        status="excluded"
    else
        status="complete"
    fi

    if [ "${status}" = "complete" ]; then
        missing_files_value=""
        printf '%s\n' "${sample_label}" >> "${temporary_manifest}"
        complete_count=$((complete_count + 1))
    else
        missing_files_value="reason=${exclusion_reason}"
        if [ "${#missing_files[@]}" -gt 0 ]; then
            missing_list=$(IFS=';'; printf '%s' "${missing_files[*]}")
            missing_files_value="${missing_files_value};${missing_list}"
        fi
        excluded_count=$((excluded_count + 1))
        echo "audit_vf_alignments: excluding ${sample}: \
${missing_files_value}" >&2
    fi

    printf '%s,%s,%s,%s,%s,%s\n' \
        "${category}" \
        "${origin}" \
        "${sample_id}" \
        "${sample}" \
        "${status}" \
        "${missing_files_value}" \
        >> "${temporary_qc}"
done < "${expected_samples}"

echo "audit_vf_alignments: complete=${complete_count} \
excluded=${excluded_count}"
if [ "${complete_count}" -eq 0 ]; then
    echo "audit_vf_alignments: ERROR! no complete VFDB alignments" >&2
    exit 1
fi

mv -f "${temporary_qc}" "${qc_output}"
mv -f "${temporary_manifest}" "${complete_samples_output}"
temporary_files=(
    "${phatyp_samples}"
    "${gff_samples}"
    "${phamer_samples}"
    "${phamer_phage_samples}"
    "${non_phage_samples}"
    "${expected_samples}"
)
