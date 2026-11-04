#!/bin/bash
###############################################################################
#       Aydin Karatas
#       Project Coprolite Viromes
#       collect_all_vf_hits.sh
###############################################################################


set -euo pipefail

if [ "$#" -lt 1 ] || [ "$#" -gt 4 ]; then
    echo "Usage: bash data_wrangling/collect_all_vf_hits.sh PROJECT_DIR [OUTPUT_CSV COMPLETE_SAMPLES_FILE] VFDB_VERSION" >&2
    exit 2
fi

project_dir="${1%/}"
version="${4:?VFDB_VERSION is required as the fourth argument}"
case "$version" in
    VFDB_setA|VFDB_setB) ;;
    *) echo "collect_all_vf_hits: invalid VFDB version" >&2; exit 2 ;;
esac
alignment_dir="${project_dir}/alignment/vfdb_all_orfs/${version}"
output_dir="${project_dir}/data"
output_csv="${2:-${output_dir}/all_vf_hits.csv}"
complete_samples_file="${3:-}"
output_parent=$(dirname "${output_csv}")
temporary_csv=""

cleanup() {
    if [ -n "${temporary_csv}" ] && [ -e "${temporary_csv}" ]; then
        rm -f "${temporary_csv}"
    fi
}
trap cleanup EXIT

echo "collect_all_vf_hits: searching for VF alignment tables in ${alignment_dir}"

mkdir -p "${output_dir}" "${output_parent}"

if [ -n "${complete_samples_file}" ] && [ ! -s "${complete_samples_file}" ]; then
    echo "collect_all_vf_hits: ERROR! missing complete-samples file: ${complete_samples_file}" >&2
    exit 1
fi

table_files=()
while IFS= read -r table_file; do
    table_name=$(basename "$(dirname "${table_file}")")
    sample_label="${table_name%_vf}"
    if [ -n "${complete_samples_file}" ] && \
        ! grep -Fqx "${sample_label}" "${complete_samples_file}"
    then
        continue
    fi
    table_files+=("${table_file}")
done < <(
    find "${alignment_dir}" -mindepth 2 -maxdepth 2 -type f \
        -path '*_vf/table.txt' 2>/dev/null | sort
)

if [ "${#table_files[@]}" -eq 0 ]; then
    echo "collect_all_vf_hits: ERROR! no VF table.txt files found in ${alignment_dir}" >&2
    exit 1
fi

echo "collect_all_vf_hits: found ${#table_files[@]} table.txt files"
echo "collect_all_vf_hits: writing combined CSV to ${output_csv}"

temporary_csv=$(mktemp "${output_parent}/.$(basename "${output_csv}").XXXXXX")

printf '%s\n' \
"vfdb_version,orf_pool,category,origin,sample_id,target_name,accession,query_name,query_accession,full_seq_evalue,full_seq_score,full_seq_bias,best_domain_evalue,best_domain_score,best_domain_bias,exp,reg,clu,ov,env,dom,rep,inc,description" \
> "${temporary_csv}"

for table_file in "${table_files[@]}"; do
    table_dir=$(dirname "${table_file}")
    table_name=$(basename "${table_dir}")

    category="${table_name%%-*}"
    remainder="${table_name#*-}"
    origin="${remainder%%_*}"
    sample_part="${remainder#*_}"
    sample_id="${sample_part%_vf}"

    if [ "${category}" = "${table_name}" ] || [ "${origin}" = "${remainder}" ] || [ -z "${sample_id}" ]; then
        echo "collect_all_vf_hits: ERROR! could not parse metadata from ${table_name}" >&2
        exit 1
    fi

    echo "collect_all_vf_hits: parsing ${table_file}"

    awk -v version="${version}" -v category="${category}" -v origin="${origin}" -v sample_id="${sample_id}" '
        function csv_escape(value, escaped) {
            escaped = value
            gsub(/"/, "\"\"", escaped)
            return "\"" escaped "\""
        }

        /^[[:space:]]*$/ { next }
        /^#/ { next }

        NF < 18 {
            print "collect_all_vf_hits: ERROR! malformed HMMER row in " \
                FILENAME ":" FNR > "/dev/stderr"
            exit 2
        }

        {
            description = ""
            if (NF >= 19) {
                description = $19
                for (i = 20; i <= NF; i++) {
                    description = description " " $i
                }
            }

            printf "%s,%s,%s,%s,%s", csv_escape(version), \
                csv_escape("all_bacterial_prokka_cds"), csv_escape(category), \
                csv_escape(origin), csv_escape(sample_id)
            for (i = 1; i <= 18; i++) {
                printf ",%s", csv_escape($i)
            }
            printf ",%s\n", csv_escape(description)
        }
    ' "${table_file}" >> "${temporary_csv}"
done

mv -f "${temporary_csv}" "${output_csv}"
temporary_csv=""
echo "collect_all_vf_hits: finished"
