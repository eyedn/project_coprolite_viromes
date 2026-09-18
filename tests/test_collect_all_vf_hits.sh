#!/usr/bin/env bash

set -euo pipefail

repo_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
test_dir=$(mktemp -d)
trap 'rm -rf "${test_dir}"' EXIT

project_dir="${test_dir}/project"
table_dir="${project_dir}/alignment/pal-AUT_S1_vf"
output_csv="${project_dir}/data/all_vf_hits.csv"

mkdir -p "${table_dir}" "${project_dir}/data"
printf 'previous output\n' > "${output_csv}"

cat > "${table_dir}/table.txt" <<'EOF'
# hmmer table
# target accession query accession
# fields
VF_A ACC query_1 QACC 1e-20 50 1 1e-20 50 1 1 1 1 1 1 1 1 1 a description
EOF

bash "${repo_dir}/data_wrangling/collect_all_vf_hits.sh" \
    "${project_dir}" "${output_csv}"

header=$(head -n 1 "${output_csv}")
expected_header='category,origin,sample_id,target_name,accession,query_name,query_accession,full_seq_evalue,full_seq_score,full_seq_bias,best_domain_evalue,best_domain_score,best_domain_bias,exp,reg,clu,ov,env,dom,rep,inc,description'

test "${header}" = "${expected_header}"
test "$(wc -l < "${output_csv}")" -eq 2
rg -q '^"pal","AUT","S1","VF_A"' "${output_csv}"
