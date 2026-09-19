#!/bin/bash
###############################################################################
#       Aydin Karatas
#       Project Coprolite Viromes
#       3a_get_alignment_counts.sh
###############################################################################
set -euo pipefail

if [ "$#" -ne 3 ]; then
    echo "Usage: pipeline/3a_get_alignment_counts.sh ORIGIN PROJECT_DIR NUM_CORES" >&2
    exit 2
fi

origin="$1"
project_dir="${2%/}"
num_cores="$3"
script_dir="$HOME/project_coprolite_viromes"

if [ ! -d "${script_dir}" ]; then
    echo "3a_get_alignment_counts: missing code directory: ${script_dir}" >&2
    exit 1
fi
cd "${script_dir}"

# Set up the cluster environment when the Hoffman2 module files are present.
if [ -d "${script_dir}/general_bash_functions" ]; then
    for file_path in "${script_dir}"/general_bash_functions/*; do
        source "${file_path}"
    done
fi
if [ -f /u/local/Modules/default/init/modules.sh ]; then
    source /u/local/Modules/default/init/modules.sh
    module load python
fi
if [ -n "${python_env:-}" ] && [ -f "${python_env}" ]; then
    source "${python_env}"
fi

data_dir="${project_dir}/data"
alignment_dir="${project_dir}/alignment"
annotation_dir="${project_dir}/genome_annotation"
prediction_dir="${project_dir}/phage_predictions"
# The legacy Python collector expands or substitutes these ! path tokens.
vf_alignment_pattern="${alignment_dir}/!vf"
annotation_path_template="${annotation_dir}/!_annotation_bac_on_phage"

timestamp_message() {
    if command -v timestamp >/dev/null 2>&1; then
        timestamp
    else
        date '+%Y-%m-%d %H:%M:%S'
    fi
}

stage_message() {
    echo "==============================================================================="
    echo "$(timestamp_message): 3a_get_alignment_counts: $1"
    echo "==============================================================================="
}

require_directory() {
    if [ ! -d "$1" ]; then
        echo "$(timestamp_message): 3a_get_alignment_counts: ERROR! missing $2: $1" >&2
        exit 1
    fi
}

require_directory "${alignment_dir}" "alignment directory"
require_directory "${annotation_dir}" "genome annotation directory"
require_directory "${prediction_dir}" "PhaTYP prediction directory"
mkdir -p "${data_dir}"

vf_table_file=$(find "${alignment_dir}" -mindepth 2 -maxdepth 2 -type f \
    -path '*_vf/table.txt' -print -quit)
if [ -z "${vf_table_file}" ]; then
    echo "$(timestamp_message): 3a_get_alignment_counts: ERROR! no VF table.txt files" >&2
    exit 1
fi

phatyp_file=$(find "${prediction_dir}" -type f \
    -path '*_prediction/out/phatyp_prediction.csv' -print -quit)
if [ -z "${phatyp_file}" ]; then
    echo "$(timestamp_message): 3a_get_alignment_counts: ERROR! no PhaTYP prediction files" >&2
    exit 1
fi

gff_file=$(find "${annotation_dir}" -type f \
    -path '*_annotation_bac_on_phage/*.gff.gz' -print -quit)
if [ -z "${gff_file}" ]; then
    echo "$(timestamp_message): 3a_get_alignment_counts: ERROR! no bacterial-on-phage GFF files" >&2
    exit 1
fi

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

temporary_counts=$(mktemp "${data_dir}/.vf_alignment_counts.csv.XXXXXX")
temporary_contig_hits=$(mktemp "${data_dir}/.vf_alignment_contig_hits.csv.XXXXXX")
temporary_all_hits=$(mktemp "${data_dir}/.all_vf_hits.csv.XXXXXX")
temporary_stats=$(mktemp "${data_dir}/.phage_vf_stats.csv.XXXXXX")
temporary_qc=$(mktemp "${data_dir}/.phage_vf_stats_qc.csv.XXXXXX")
temporary_files=(
    "${temporary_counts}"
    "${temporary_contig_hits}"
    "${temporary_all_hits}"
    "${temporary_stats}"
    "${temporary_qc}"
)

stage_message "collecting legacy VFDB alignment counts"
python3 "${script_dir}/data_wrangling/get_alignment_counts.py" \
    "${vf_alignment_pattern}" \
    "${annotation_path_template}" \
    "${data_dir}" \
    "vf_alignment" \
    "${temporary_counts}" \
    "${temporary_contig_hits}"

stage_message "combining all VFDB hits"
bash "${script_dir}/data_wrangling/collect_all_vf_hits.sh" \
    "${project_dir}" \
    "${temporary_all_hits}"

stage_message "calculating phage-level VFDB statistics"
bash "${script_dir}/data_wrangling/collect_phage_vf_stats.sh" \
    "${project_dir}" \
    "${temporary_all_hits}" \
    "${temporary_stats}" \
    "${temporary_qc}"

for output_file in \
    "${temporary_counts}" \
    "${temporary_contig_hits}" \
    "${temporary_all_hits}" \
    "${temporary_stats}" \
    "${temporary_qc}"
do
    if [ ! -s "${output_file}" ]; then
        echo "$(timestamp_message): 3a_get_alignment_counts: ERROR! expected VFDB output is empty: ${output_file}" >&2
        exit 1
    fi
done

stage_message "publishing five VFDB output files"
mv -f "${temporary_counts}" "${data_dir}/vf_alignment_counts.csv"
mv -f "${temporary_contig_hits}" "${data_dir}/vf_alignment_contig_hits.csv"
mv -f "${temporary_all_hits}" "${data_dir}/all_vf_hits.csv"
mv -f "${temporary_stats}" "${data_dir}/phage_vf_stats.csv"
mv -f "${temporary_qc}" "${data_dir}/phage_vf_stats_qc.csv"
temporary_files=()

stage_message "VFDB aggregation complete for ${origin} with ${num_cores} cores"
