#!/usr/bin/env bash
###############################################################################
#       Aydin Karatas
#       Project Coprolite Viromes
#       4_analyze_checkv_genomes.sh
###############################################################################


code_dir="${VIROME_CODE_DIR:-$HOME/project_coprolite_viromes}"
source "$code_dir/general_bash_functions/slurm.sh"


set -euo pipefail

if [ "$#" -ne 3 ]; then
    echo "Usage: pipeline/4_analyze_checkv_genomes.sh " \
        "CHECKV_FILTER PROJECT_DIR NUM_CORES" >&2
    exit 2
fi

filter_job="$1"
project_dir="${2%/}"
num_cores="$3"
validate_cpus "$num_cores" || exit 2
checkv_filter="${filter_job#checkv-}"
script_dir="${VIROME_CODE_DIR:-$HOME/project_coprolite_viromes}"

if [ ! -d "${script_dir}" ]; then
    echo "4_analyze_checkv_genomes: missing code directory: ${script_dir}" >&2
    exit 1
fi
cd "${script_dir}"

if [ "$checkv_filter" != "conservative" ] \
    && [ "$checkv_filter" != "aggressive" ]; then
    echo "4_analyze_checkv_genomes: invalid filter: ${filter_job}" >&2
    exit 2
fi

for file_path in "${script_dir}"/general_bash_functions/*; do
    source "$file_path"
done
source "${script_dir}/phabox_predictions/bash_functions/get_lifestyles.sh"
source "${script_dir}/phabox_predictions/bash_functions/get_families.sh"
source "${script_dir}/prokka_annotations/bash_functions/prokka_annotator.sh"

input_dir="${project_dir}/checkv_input/${checkv_filter}"
output_dir="${project_dir}/checkv_genomes/${checkv_filter}"
prediction_dir="${output_dir}/predictions"
bacterial_dir="${output_dir}/annotations/bacterial"
viral_dir="${output_dir}/annotations/viral"
vf_dir="${output_dir}/vf_alignment_all_orfs"
input_fasta="${input_dir}/genomes.fa.gz"
working_fasta="${output_dir}/working_genomes.fa"
prefix="checkv_${checkv_filter}"

for input_path in \
    "${input_fasta}" \
    "${input_dir}/quality_summary.tsv" \
    "${input_dir}/complete_contigs.txt"
do
    if [ ! -s "$input_path" ]; then
        echo "4_analyze_checkv_genomes: missing input: ${input_path}" >&2
        exit 1
    fi
done

mkdir -p \
    "$output_dir" \
    "$prediction_dir" \
    "${output_dir}/annotations" \
    "$vf_dir"

cleanup() {
    rm -f "$working_fasta"
}
trap cleanup EXIT
gzip -cd "$input_fasta" | awk '
    /^>/ {
        split(substr($0, 2), fields, /[[:space:]]+/)
        print ">" fields[1]
        next
    }
    { print }
' > "$working_fasta"

activate_environment phabox
get_lifestyles "$prefix" "$working_fasta" "$prediction_dir" "$num_cores"
get_families "$prefix" "$working_fasta" "$prediction_dir" "$num_cores"

activate_environment prokka
if [ ! -s "${bacterial_dir}/${prefix}.gff" ]; then
    if [ -d "$bacterial_dir" ]; then
        if [ -n "$(find "$bacterial_dir" -mindepth 1 -print -quit)" ]; then
            echo "4_analyze_checkv_genomes:" \
                "incomplete bacterial Prokka output" >&2
            exit 1
        fi
        rmdir "$bacterial_dir"
    fi
    prokka_annotator \
        "$prefix" "$working_fasta" no_data "$bacterial_dir" \
        Bacteria bacterial "$num_cores" checkv_tolerant
fi
if ! checkv_prokka_outputs_complete "$bacterial_dir" "$prefix"; then
    echo "4_analyze_checkv_genomes: incomplete bacterial Prokka output" >&2
    exit 1
fi
if [ ! -s "${viral_dir}/${prefix}.gff" ]; then
    if [ -d "$viral_dir" ]; then
        if [ -n "$(find "$viral_dir" -mindepth 1 -print -quit)" ]; then
            echo "4_analyze_checkv_genomes:" \
                "incomplete viral Prokka output" >&2
            exit 1
        fi
        rmdir "$viral_dir"
    fi
    prokka_annotator \
        "$prefix" "$working_fasta" no_data "$viral_dir" \
        Viruses viral "$num_cores" checkv_tolerant
fi
if ! checkv_prokka_outputs_complete "$viral_dir" "$prefix"; then
    echo "4_analyze_checkv_genomes: incomplete viral Prokka output" >&2
    exit 1
fi

activate_environment python
python3 "${script_dir}/data_wrangling/prepare_checkv_prokka.py" \
    "${bacterial_dir}/${prefix}.gff" \
    "${bacterial_dir}/valid_features.csv"
python3 "${script_dir}/data_wrangling/prepare_checkv_prokka.py" \
    "${viral_dir}/${prefix}.gff" \
    "${viral_dir}/valid_features.csv"

# reuse Prokka calls, searching both full-pool reference versions.
for version in VFDB_setA VFDB_setB; do
    case "$version" in
        VFDB_setA) vf_database="${ref_db}/VFDB_setA_pro_20230917.txt" ;;
        VFDB_setB) vf_database="${ref_db}/VFDB_setB_pro_20260923.txt" ;;
    esac
    python3 "${script_dir}/data_wrangling/search_vfdb.py" \
        "${bacterial_dir}/${prefix}.faa" \
        "${bacterial_dir}/${prefix}.gff" "$vf_database" \
        "${vf_dir}/${version}" "$version" "$num_cores" "$hmmsearch"
done

echo "$(timestamp): step 4 complete for ${checkv_filter}"
