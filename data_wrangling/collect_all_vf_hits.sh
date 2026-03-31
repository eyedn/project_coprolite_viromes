#!/bin/bash
###############################################################################
#       Aydin Karatas
#       Project Coprolite Viromes
#       collect_all_vf_hits.sh
###############################################################################

set -euo pipefail

alignment_dir="/u/scratch/a/ayd1n/project_coprolite_viromes/alignment"
output_dir="/u/scratch/a/ayd1n/project_coprolite_viromes/data"
output_csv="${output_dir}/all_vf_hits.csv"

echo "collect_all_vf_hits: searching for VF alignment tables in ${alignment_dir}"

mkdir -p "${output_dir}"

mapfile -t table_files < <(find "${alignment_dir}" -mindepth 2 -maxdepth 2 -type f -path '*_vf/table.txt' 2>/dev/null | sort)

if [ "${#table_files[@]}" -eq 0 ]; then
    echo "collect_all_vf_hits: ERROR! no VF table.txt files found in ${alignment_dir}" >&2
    exit 1
fi

echo "collect_all_vf_hits: found ${#table_files[@]} table.txt files"
echo "collect_all_vf_hits: writing combined CSV to ${output_csv}"

printf '%s\n' \
"category,origin,sample_id,target_name,accession,query_name,query_accession,full_seq_evalue,full_seq_score,full_seq_bias,best_domain_evalue,best_domain_score,best_domain_bias,exp,reg,clu,ov,env,dom,rep,inc,description" \
> "${output_csv}"

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

    awk -v category="${category}" -v origin="${origin}" -v sample_id="${sample_id}" '
        function csv_escape(value, escaped) {
            escaped = value
            gsub(/"/, "\"\"", escaped)
            return "\"" escaped "\""
        }

        NR <= 3 { next }
        /^[[:space:]]*$/ { next }
        /^#/ { next }
        NF < 18 { next }

        {
            description = ""
            if (NF >= 19) {
                description = $19
                for (i = 20; i <= NF; i++) {
                    description = description " " $i
                }
            }

            printf "%s,%s,%s", csv_escape(category), csv_escape(origin), csv_escape(sample_id)
            for (i = 1; i <= 18; i++) {
                printf ",%s", csv_escape($i)
            }
            printf ",%s\n", csv_escape(description)
        }
    ' "${table_file}" >> "${output_csv}"
done

echo "collect_all_vf_hits: finished"
