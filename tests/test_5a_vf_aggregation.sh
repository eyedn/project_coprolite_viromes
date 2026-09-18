#!/usr/bin/env bash

###############################################################################
#           Aydin Loid Karatas
#           ---
#           University of Southern California
#           Department of Quantitative and Computational Biology
#           Mooney Lab
#           ---
#           test_5a_vf_aggregation.sh
###############################################################################

set -euo pipefail

repo_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
test_dir=$(mktemp -d)
trap 'rm -rf "${test_dir}"' EXIT

project_dir="${test_dir}/project"
data_dir="${project_dir}/data"
bin_dir="${test_dir}/bin"
real_python=$(command -v python3)

mkdir -p \
    "${project_dir}/alignment/pal-AUT_S1_vf" \
    "${project_dir}/alignment/!vf" \
    "${project_dir}/genome_annotation/!_annotation_bac_on_phage" \
    "${project_dir}/genome_annotation/pal-AUT_S1_annotation_bac_on_phage" \
    "${project_dir}/phage_predictions/pal-AUT_S1_prediction/out" \
    "${data_dir}" \
    "${bin_dir}"

cat > "${project_dir}/alignment/pal-AUT_S1_vf/table.txt" <<'EOF'
# hmmer table
# target accession query accession
# fields
orf_1 ACC VF_A QACC 1e-20 50 1 1e-20 50 1 1 1 1 1 1 1 1 1 qualifying hit
EOF

cat > "${project_dir}/phage_predictions/pal-AUT_S1_prediction/out/phatyp_prediction.csv" <<'EOF'
Contig,Pred,Score
contig_1,virulent,0.9
EOF

printf '%s\n' \
    '##gff-version 3' \
    '##sequence-region contig_1 1 100' \
    $'contig_1\tProkka\tCDS\t1\t30\t.\t+\t0\tID=orf_1' \
    > "${test_dir}/sample.gff"
gzip -c "${test_dir}/sample.gff" \
    > "${project_dir}/genome_annotation/pal-AUT_S1_annotation_bac_on_phage/sample.gff.gz"

cat > "${bin_dir}/python3" <<EOF
#!/usr/bin/env bash
if [[ "\${1}" == *get_alignment_counts.py ]]; then
    printf 'metric,value\ncount,1\n' > "\${6}"
    printf 'contig,hits\ncontig_1,1\n' > "\${7}"
    exit 0
fi
exec "${real_python}" "\$@"
EOF
chmod +x "${bin_dir}/python3"

PATH="${bin_dir}:${PATH}" bash "${repo_dir}/pipeline/5a_get_alignment_counts.sh" \
    all "${project_dir}" 1

for output_file in \
    vf_alignment_counts.csv \
    vf_alignment_contig_hits.csv \
    all_vf_hits.csv \
    phage_vf_stats.csv \
    phage_vf_stats_qc.csv
do
    test -s "${data_dir}/${output_file}"
done

test "$(head -n 1 "${data_dir}/all_vf_hits.csv")" = \
    'category,origin,sample_id,target_name,accession,query_name,query_accession,full_seq_evalue,full_seq_score,full_seq_bias,best_domain_evalue,best_domain_score,best_domain_bias,exp,reg,clu,ov,env,dom,rep,inc,description'
test "$(head -n 1 "${data_dir}/vf_alignment_counts.csv")" = \
    'metric,value'
test "$(head -n 1 "${data_dir}/vf_alignment_contig_hits.csv")" = \
    'contig,hits'
test "$(head -n 1 "${data_dir}/phage_vf_stats.csv" | tr -d '\r')" = \
    'category,origin,sample_id,sample,contig_id,lifestyle_raw,lifestyle,phatyp_score,contig_length,total_bacterial_orfs,qualifying_vf_orfs,vf_present,vf_orf_prevalence,vf_covered_bases,vf_contig_coverage'
test "$(head -n 1 "${data_dir}/phage_vf_stats_qc.csv" | tr -d '\r')" = \
    'metric,value,details'
rg -q '^pal,AUT,S1,pal.AUT_S1,contig_1,virulent,Lytic' \
    "${data_dir}/phage_vf_stats.csv"

checksums_before=$(shasum "${data_dir}"/*.csv)
PATH="${bin_dir}:${PATH}" bash "${repo_dir}/pipeline/5a_get_alignment_counts.sh" \
    all "${project_dir}" 1
checksums_after=$(shasum "${data_dir}"/*.csv)
test "${checksums_before}" = "${checksums_after}"

assert_outputs_unchanged() {
    test "$(shasum "${data_dir}"/*.csv)" = "${checksums_after}"
}

prediction_file="${project_dir}/phage_predictions/pal-AUT_S1_prediction/out/phatyp_prediction.csv"
gff_file="${project_dir}/genome_annotation/pal-AUT_S1_annotation_bac_on_phage/sample.gff.gz"
table_file="${project_dir}/alignment/pal-AUT_S1_vf/table.txt"

mv "${prediction_file}" "${prediction_file}.missing"
if PATH="${bin_dir}:${PATH}" bash \
    "${repo_dir}/pipeline/5a_get_alignment_counts.sh" all "${project_dir}" 1
then
    echo "expected missing PhaTYP input to fail" >&2
    exit 1
fi
assert_outputs_unchanged
mv "${prediction_file}.missing" "${prediction_file}"

mv "${gff_file}" "${gff_file}.missing"
if PATH="${bin_dir}:${PATH}" bash \
    "${repo_dir}/pipeline/5a_get_alignment_counts.sh" all "${project_dir}" 1
then
    echo "expected missing GFF input to fail" >&2
    exit 1
fi
assert_outputs_unchanged
mv "${gff_file}.missing" "${gff_file}"

mv "${table_file}" "${table_file}.missing"
if PATH="${bin_dir}:${PATH}" bash \
    "${repo_dir}/pipeline/5a_get_alignment_counts.sh" all "${project_dir}" 1
then
    echo "expected missing VF table to fail" >&2
    exit 1
fi
assert_outputs_unchanged
mv "${table_file}.missing" "${table_file}"

cp "${prediction_file}" "${prediction_file}.valid"
printf 'Contig,Pred,Score\nmissing_contig,virulent,0.9\n' > "${prediction_file}"
if PATH="${bin_dir}:${PATH}" bash \
    "${repo_dir}/pipeline/5a_get_alignment_counts.sh" all "${project_dir}" 1
then
    echo "expected invalid PhaTYP-to-GFF join to fail" >&2
    exit 1
fi
assert_outputs_unchanged
mv "${prediction_file}.valid" "${prediction_file}"
