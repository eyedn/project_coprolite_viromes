#!/usr/bin/env bash
###############################################################################
#       Aydin Karatas
#       Project Coprolite Viromes
#       4a_get_checkv_genome_stats.sh
###############################################################################


code_dir="${VIROME_CODE_DIR:-$HOME/project_coprolite_viromes}"
source "$code_dir/general_bash_functions/slurm.sh"


set -euo pipefail

if [ "$#" -ne 3 ]; then
    echo "Usage: pipeline/4a_get_checkv_genome_stats.sh " \
        "ORIGIN PROJECT_DIR NUM_CORES" >&2
    exit 2
fi

origin="$1"
project_dir="${2%/}"
num_cores="$3"
validate_cpus "$num_cores" || exit 2
script_dir="${VIROME_CODE_DIR:-$HOME/project_coprolite_viromes}"

if [ ! -d "${script_dir}" ]; then
    echo "4a_get_checkv_genome_stats: missing code directory: ${script_dir}" >&2
    exit 1
fi
cd "${script_dir}"

if [ "$origin" != "all" ]; then
    echo "4a_get_checkv_genome_stats: ORIGIN must be all" >&2
    exit 2
fi

for file_path in "${script_dir}"/general_bash_functions/*; do
    source "$file_path"
done
activate_environment python
for input_dir in samples data checkv_input checkv_genomes; do
    if [[ ! -d $project_dir/$input_dir ]]; then
        echo "4a: missing input directory: $project_dir/$input_dir" >&2
        exit 1
    fi
done

for version in VFDB_setA VFDB_setB; do
    python3 "${script_dir}/data_wrangling/collect_checkv_genome_stats.py" \
        "$project_dir" --vfdb-version "$version"
done

# supplement filtered features with every conservative viral CDS for maps.
python3 "${script_dir}/data_wrangling/export_checkv_viral_cds.py" \
    "$project_dir" "${project_dir}/data/checkv_viral_cds_conservative.csv"

echo "4a_get_checkv_genome_stats: complete with ${num_cores} requested cores"
