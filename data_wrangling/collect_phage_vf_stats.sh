#!/bin/bash
###############################################################################
#       Aydin Karatas
#       Project Coprolite Viromes
#       collect_phage_vf_stats.sh
###############################################################################
set -euo pipefail

if [ "$#" -ne 1 ] && [ "$#" -ne 4 ] && [ "$#" -ne 5 ]; then
    echo "Usage: bash data_wrangling/collect_phage_vf_stats.sh PROJECT_DIR [VF_HITS_FILE STATS_OUTPUT QC_OUTPUT COMPLETE_SAMPLES_FILE]" >&2
    exit 2
fi

project_dir="${1%/}"
prediction_dir="${project_dir}/phage_predictions"
annotation_dir="${project_dir}/genome_annotation"
data_dir="${project_dir}/data"
vf_hits_file="${data_dir}/all_vf_hits.csv"
script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

complete_samples_file=""
if [ "$#" -ge 4 ]; then
    vf_hits_file="${2}"
    stats_output="${3}"
    qc_output="${4}"
    if [ "$#" -eq 5 ]; then
        complete_samples_file="${5}"
    fi
else
    stats_output="${data_dir}/phage_vf_stats.csv"
    qc_output="${data_dir}/phage_vf_stats_qc.csv"
fi

for required_dir in \
    "${prediction_dir}" \
    "${annotation_dir}" \
    "${data_dir}"
do
    if [ ! -d "${required_dir}" ]; then
        echo "collect_phage_vf_stats: missing directory: ${required_dir}" >&2
        exit 1
    fi
done

if [ ! -f "${vf_hits_file}" ]; then
    echo "collect_phage_vf_stats: missing upstream file: ${vf_hits_file}" >&2
    echo "Run data_wrangling/collect_all_vf_hits.sh first." >&2
    exit 1
fi
if [ -n "${complete_samples_file}" ] && [ ! -s "${complete_samples_file}" ]; then
    echo "collect_phage_vf_stats: missing complete-samples file: ${complete_samples_file}" >&2
    exit 1
fi

phatyp_files=()
while IFS= read -r file_path; do
    phatyp_files+=("${file_path}")
done < <(
    find "${prediction_dir}" -type f \
        -path '*_prediction/out/phatyp_prediction.csv' | sort
)

gff_files=()
while IFS= read -r file_path; do
    gff_files+=("${file_path}")
done < <(
    find "${annotation_dir}" -type f \
        -path '*_annotation_bac_on_phage/*.gff.gz' | sort
)

if [ "${#phatyp_files[@]}" -eq 0 ]; then
    echo "collect_phage_vf_stats: no PhaTYP files found" >&2
    exit 1
fi
if [ "${#gff_files[@]}" -eq 0 ]; then
    echo "collect_phage_vf_stats: no Prokka GFF files found" >&2
    exit 1
fi

echo "collect_phage_vf_stats: PhaTYP files: ${#phatyp_files[@]}"
echo "collect_phage_vf_stats: Prokka GFF files: ${#gff_files[@]}"
python_command=(
    python3
    "${script_dir}/collect_phage_vf_stats.py"
    "${project_dir}"
    --vf-hits-file "${vf_hits_file}"
    --stats-output "${stats_output}"
    --qc-output "${qc_output}"
)
if [ -n "${complete_samples_file}" ]; then
    python_command+=(--complete-samples-file "${complete_samples_file}")
fi
"${python_command[@]}"
echo "collect_phage_vf_stats: wrote ${stats_output}"
echo "collect_phage_vf_stats: wrote ${qc_output}"
