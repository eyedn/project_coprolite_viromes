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

data_dir="${project_dir}/data"
alignment_dir="${project_dir}/alignment"
annotation_dir="${project_dir}/genome_annotation"
prediction_dir="${project_dir}/phage_predictions"
# the legacy Python collector expands or substitutes these ! path tokens.
annotation_path_template="${annotation_dir}/!_annotation_bac_on_phage"

timestamp_message() {
    if command -v timestamp >/dev/null 2>&1; then
        timestamp
    else
        date '+%Y-%m-%d %H:%M:%S'
    fi
}

stage_message() {
    {
        echo "==============================================================================="
        echo "$(timestamp_message): 3a_get_alignment_counts: $1"
        echo "==============================================================================="
    } >&2
}

start_phase() {
    phase="$1"
    phase_started=$SECONDS
    stage_message "version=${version} phase=${phase} event=start"
}

end_phase() {
    stage_message "version=${version} phase=${phase} event=end phase_elapsed=$((SECONDS - phase_started))s elapsed=$((SECONDS - stage_started))s"
}

require_directory() {
    if [ ! -d "$1" ]; then
        echo "$(timestamp_message): 3a_get_alignment_counts: ERROR! missing $2: $1" >&2
        exit 1
    fi
}

stage_started=$SECONDS
phase_started=$SECONDS
version=unassigned
phase=startup
temporary_files=()
cleanup() {
    local file_path
    for file_path in "${temporary_files[@]:-}"; do
        if [ -e "${file_path}" ]; then
            rm -f "${file_path}"
        fi
    done
}
finish() {
    local exit_status=$?
    if [ "$exit_status" -ne 0 ]; then
        stage_message "version=${version} phase=${phase} event=failed exit_status=${exit_status} phase_elapsed=$((SECONDS - phase_started))s elapsed=$((SECONDS - stage_started))s"
    fi
    cleanup
    return "$exit_status"
}
trap finish EXIT

stage_message "hostname=$(hostname) job_id=${JOB_ID:-unavailable} task_id=${SGE_TASK_ID:-unavailable} allocated_slots=${NSLOTS:-unavailable} requested_cores=${num_cores} origin=${origin}"
stage_message "project_path=${project_dir} code_path=${script_dir}"
stage_message "effective shell memory limits (soft; includes data, RSS, virtual memory)"
ulimit -Sa >&2
stage_message "effective shell memory limits (hard; includes data, RSS, virtual memory)"
ulimit -Ha >&2

# set up the cluster environment when the Hoffman2 module files are present.
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

require_directory "${alignment_dir}" "alignment directory"
require_directory "${annotation_dir}" "genome annotation directory"
require_directory "${prediction_dir}" "PhaTYP prediction directory"
mkdir -p "${data_dir}"

# publish independently validated full-pool bundles for each reference.
for version in VFDB_setA VFDB_setB; do
    start_phase "bundle setup"
    suffix=""
    if [ "$version" = VFDB_setA ]; then
        suffix="_VFDB_setA"
    fi
    version_alignment_dir="${alignment_dir}/vfdb_all_orfs/${version}"
    vf_alignment_pattern="${version_alignment_dir}/!vf"
    temporary_dir=$(mktemp -d "${data_dir}/.vfdb_bundle.XXXXXX")
    temporary_files=()
    for name in vf_alignment_counts vf_alignment_contig_hits all_vf_hits \
        phage_vf_stats phage_vf_stats_qc vf_alignment_qc phage_vf_orfs \
        sample_vf_stats complete_samples; do
        temporary_files+=("${temporary_dir}/${name}.csv")
    done
    end_phase
    start_phase "auditing"
    bash "${script_dir}/data_wrangling/audit_vf_alignments.sh" \
        "$project_dir" "${temporary_dir}/vf_alignment_qc.csv" \
        "${temporary_dir}/complete_samples.csv" "$version"
    end_phase

    # the E-value-only legacy products are diagnostics, never prevalence inputs.
    start_phase "legacy count collection"
    python3 "${script_dir}/data_wrangling/get_alignment_counts.py" \
        "$vf_alignment_pattern" "$annotation_path_template" "$data_dir" \
        vf_alignment "${temporary_dir}/vf_alignment_counts.csv" \
        "${temporary_dir}/vf_alignment_contig_hits.csv" \
        "${temporary_dir}/complete_samples.csv"
    end_phase
    start_phase "combined-hit collection"
    bash "${script_dir}/data_wrangling/collect_all_vf_hits.sh" \
        "$project_dir" "${temporary_dir}/all_vf_hits.csv" \
        "${temporary_dir}/complete_samples.csv" "$version"
    end_phase
    start_phase "statistics collection"
    statistics_command=(python3)
    if [ "$(uname -s)" = Linux ] && [ -x /usr/bin/time ]; then
        statistics_command=(/usr/bin/time -v python3)
    else
        stage_message "version=${version} phase=${phase}: /usr/bin/time -v timing statistics unavailable; running collector normally"
    fi
    "${statistics_command[@]}" \
        "${script_dir}/data_wrangling/collect_phage_vf_stats.py" \
        "$project_dir" --vfdb-version "$version" \
        --vf-hits-file "${temporary_dir}/all_vf_hits.csv" \
        --stats-output "${temporary_dir}/phage_vf_stats.csv" \
        --qc-output "${temporary_dir}/phage_vf_stats_qc.csv" \
        --orfs-output "${temporary_dir}/phage_vf_orfs.csv" \
        --sample-stats-output "${temporary_dir}/sample_vf_stats.csv" \
        --complete-samples-file "${temporary_dir}/complete_samples.csv"
    end_phase
    start_phase "validation"
    for name in vf_alignment_counts vf_alignment_contig_hits all_vf_hits \
        phage_vf_stats phage_vf_stats_qc vf_alignment_qc phage_vf_orfs \
        sample_vf_stats; do
        if [ ! -s "${temporary_dir}/${name}.csv" ]; then
            echo "3a: empty ${version} output: ${name}" >&2
            exit 1
        fi
    done
    end_phase
    start_phase "publication"
    for name in vf_alignment_counts vf_alignment_contig_hits all_vf_hits \
        phage_vf_stats phage_vf_stats_qc vf_alignment_qc phage_vf_orfs \
        sample_vf_stats; do
        mv "${temporary_dir}/${name}.csv" \
            "${data_dir}/${name}${suffix}.csv"
    done
    rm -f "${temporary_dir}/complete_samples.csv"
    rmdir "$temporary_dir"
    temporary_files=()
    end_phase
done
stage_message "VFDB aggregation complete for ${origin} with ${num_cores} cores; elapsed=$((SECONDS - stage_started))s"
