#!/bin/bash
###############################################################################
#       Aydin Karatas
#       Project Coprolite Viromes
#       test_step4_shell_contracts.sh
###############################################################################
set -euo pipefail

repo_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)

rg -q -- '--threads "?\$\{?num_cores' \
    "${repo_dir}/phabox_predictions/bash_functions/get_lifestyles.sh"
rg -q -- '--threads "?\$\{?num_cores' \
    "${repo_dir}/phabox_predictions/bash_functions/get_families.sh"
rg -q 'if \[ -s .*phatyp_prediction.csv' \
    "${repo_dir}/phabox_predictions/bash_functions/get_lifestyles.sh"
rg -q 'if \[ -s .*phagcn_prediction.csv' \
    "${repo_dir}/phabox_predictions/bash_functions/get_families.sh"
rg -q 'Predict phage hosts.*CHERRY' \
    "${repo_dir}/phabox_predictions/bash_functions/get_hosts.sh"
rg -q 'Identify phage contigs.*PhaMer' \
    "${repo_dir}/phabox_predictions/bash_functions/get_phages.sh"

if rg -q 'gunzip .*contigs_file|gzip "\$\{contigs_file\}"' \
    "${repo_dir}/phabox_predictions/bash_functions/get_lifestyles.sh" \
    "${repo_dir}/phabox_predictions/bash_functions/get_families.sh"
then
    echo "PhaBOX helpers must not rewrite canonical input FASTAs" >&2
    exit 1
fi

rg -q 'checkv-conservative' "${repo_dir}/run_step.sh"
rg -q 'checkv-aggressive' "${repo_dir}/run_step.sh"
rg -q 'checkv_genomes/\$\{checkv_filter\}' \
    "${repo_dir}/pipeline/4_analyze_checkv_genomes.sh"

if rg -q 'genome_annotation|phage_predictions|alignment/' \
    "${repo_dir}/pipeline/4_analyze_checkv_genomes.sh"
then
    echo "step 4 must be isolated from contig-level output directories" >&2
    exit 1
fi
