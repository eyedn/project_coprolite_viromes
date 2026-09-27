#!/usr/bin/env bash
###############################################################################
#       Aydin Karatas
#       Project Coprolite Viromes
#       audit_vf_alignments.sh
###############################################################################
set -euo pipefail

if [ "$#" -ne 3 ]; then
    echo "Usage: bash data_wrangling/audit_vf_alignments.sh PROJECT_DIR QC_OUTPUT COMPLETE_SAMPLES_OUTPUT" >&2
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

for required_dir in \
    "${alignment_dir}" \
    "${annotation_dir}" \
    "${prediction_dir}"
do
    if [ ! -d "${required_dir}" ]; then
        echo "audit_vf_alignments: ERROR! missing directory: ${required_dir}" >&2
        exit 1
    fi
done

qc_parent=$(dirname "${qc_output}")
manifest_parent=$(dirname "${complete_samples_output}")
mkdir -p "${qc_parent}" "${manifest_parent}"

phatyp_samples=$(mktemp "${qc_parent}/.phatyp_samples.XXXXXX")
gff_samples=$(mktemp "${qc_parent}/.gff_samples.XXXXXX")
temporary_qc=$(mktemp "${qc_parent}/.$(basename "${qc_output}").XXXXXX")
temporary_manifest=$(
    mktemp "${manifest_parent}/.$(basename "${complete_samples_output}").XXXXXX"
)
temporary_files=(
    "${phatyp_samples}"
    "${gff_samples}"
    "${temporary_qc}"
    "${temporary_manifest}"
)

find "${prediction_dir}" -type f \
    -path '*_prediction/out/phatyp_prediction.csv' \
    -print | while IFS= read -r file_path; do
        prediction_output_dir=$(dirname "${file_path}")
        prediction_sample_dir=$(dirname "${prediction_output_dir}")
        sample_directory=$(basename "${prediction_sample_dir}")
        printf '%s\n' "${sample_directory%_prediction}"
    done | sort -u > "${phatyp_samples}"

find "${annotation_dir}" -type f \
    -path '*_annotation_bac_on_phage/*.gff.gz' \
    -print | while IFS= read -r file_path; do
        sample_directory=$(basename "$(dirname "${file_path}")")
        printf '%s\n' "${sample_directory%_annotation_bac_on_phage}"
    done | sort -u > "${gff_samples}"

if [ ! -s "${phatyp_samples}" ] || [ ! -s "${gff_samples}" ]; then
    echo "audit_vf_alignments: ERROR! expected nonempty PhaTYP and GFF sample sets" >&2
    exit 1
fi

if ! cmp -s "${phatyp_samples}" "${gff_samples}"; then
    echo "audit_vf_alignments: ERROR! PhaTYP and GFF sample sets differ" >&2
    comm -3 "${phatyp_samples}" "${gff_samples}" >&2
    exit 1
fi

printf '%s\n' \
    'category,origin,sample_id,sample,status,missing_files' \
    > "${temporary_qc}"

complete_count=0
excluded_count=0
while IFS= read -r sample_label; do
    if [[ ! "${sample_label}" =~ ^([^-]+)-([^_]+)_(.+)$ ]]; then
        echo "audit_vf_alignments: ERROR! invalid sample label: ${sample_label}" >&2
        exit 1
    fi

    category="${BASH_REMATCH[1]}"
    origin="${BASH_REMATCH[2]}"
    sample_id="${BASH_REMATCH[3]}"
    sample="${category}.${origin}_${sample_id}"
    if [[ "${category}${origin}${sample_id}" == *,* ]]; then
        echo "audit_vf_alignments: ERROR! commas are not supported in sample labels" >&2
        exit 1
    fi

    sample_alignment_dir="${alignment_dir}/${sample_label}_vf"
    missing_files=()
    for required_file in table.txt results.txt; do
        if [ ! -s "${sample_alignment_dir}/${required_file}" ]; then
            missing_files+=("${required_file}")
        fi
    done

    if [ "${#missing_files[@]}" -eq 0 ]; then
        status="complete"
        missing_files_value=""
        printf '%s\n' "${sample_label}" >> "${temporary_manifest}"
        complete_count=$((complete_count + 1))
    else
        status="excluded"
        missing_files_value=$(IFS=';'; printf '%s' "${missing_files[*]}")
        excluded_count=$((excluded_count + 1))
        echo "audit_vf_alignments: excluding ${sample}: ${missing_files_value}" >&2
    fi

    printf '%s,%s,%s,%s,%s,%s\n' \
        "${category}" \
        "${origin}" \
        "${sample_id}" \
        "${sample}" \
        "${status}" \
        "${missing_files_value}" \
        >> "${temporary_qc}"
done < "${phatyp_samples}"

echo "audit_vf_alignments: complete=${complete_count} excluded=${excluded_count}"
if [ "${complete_count}" -eq 0 ]; then
    echo "audit_vf_alignments: ERROR! no complete VFDB alignments" >&2
    exit 1
fi

mv -f "${temporary_qc}" "${qc_output}"
mv -f "${temporary_manifest}" "${complete_samples_output}"
temporary_files=("${phatyp_samples}" "${gff_samples}")
