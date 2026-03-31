#!/bin/bash
###############################################################################
#       Aydin Karatas
#       Project Coprolite Viromes
#       format_network_genome_vf_hits.sh
###############################################################################

set -euo pipefail

input_no_header="/u/scratch/a/ayd1n/proteins_all_tbl.no_header.txt"
input_with_header="/u/scratch/a/ayd1n/proteins_all_tbl.txt"
output_dir="/u/scratch/a/ayd1n/project_coprolite_viromes/data"
output_csv="${output_dir}/proteins_all_hits_formatted.csv"

if [ -f "${input_no_header}" ]; then
    input_file="${input_no_header}"
elif [ -f "${input_with_header}" ]; then
    input_file="${input_with_header}"
else
    echo "format_network_genome_vf_hits: ERROR! no proteins_all_tbl input file found" >&2
    exit 1
fi

echo "format_network_genome_vf_hits: reading ${input_file}"

mkdir -p "${output_dir}"

printf '%s\n' \
"category,origin,sample_id,sample,target_name,contig_id,orf_id,accession,query_name,query_accession,full_seq_evalue,full_seq_score,full_seq_bias,best_domain_evalue,best_domain_score,best_domain_bias,exp,reg,clu,ov,env,dom,rep,inc,prodigal_metadata" \
> "${output_csv}"

awk '
    function csv_escape(value, escaped) {
        escaped = value
        gsub(/"/, "\"\"", escaped)
        return "\"" escaped "\""
    }

    /^[[:space:]]*$/ { next }
    /^#/ { next }
    NF < 18 { next }

    {
        target_name = $1

        split(target_name, target_parts, "_")
        if (length(target_parts) < 4) {
            next
        }

        split(target_parts[1], sample_parts, "-")
        if (length(sample_parts) < 2) {
            next
        }

        category = sample_parts[1]
        origin = sample_parts[2]
        sample_id = target_parts[2]
        sample = category "." origin "_" sample_id
        orf_id = target_parts[length(target_parts)]

        contig_id = target_parts[3]
        for (i = 4; i < length(target_parts); i++) {
            contig_id = contig_id "_" target_parts[i]
        }

        prodigal_metadata = ""
        if (NF >= 19) {
            prodigal_metadata = $19
            for (i = 20; i <= NF; i++) {
                prodigal_metadata = prodigal_metadata " " $i
            }
        }

        printf "%s,%s,%s,%s", csv_escape(category), csv_escape(origin), csv_escape(sample_id), csv_escape(sample)
        printf ",%s,%s,%s", csv_escape(target_name), csv_escape(contig_id), csv_escape(orf_id)
        for (i = 2; i <= 18; i++) {
            printf ",%s", csv_escape($i)
        }
        printf ",%s\n", csv_escape(prodigal_metadata)
    }
' "${input_file}" >> "${output_csv}"

echo "format_network_genome_vf_hits: wrote ${output_csv}"
