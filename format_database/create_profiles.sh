#!/bin/bash
###############################################################################
#       Aydin Karatas
#       Project Coprolite Viromes
#       create_profiles.sh
###############################################################################


set -euo pipefail
code_dir="${VIROME_CODE_DIR:-$HOME/project_coprolite_viromes}"
source "$code_dir/general_bash_functions/slurm.sh"
source "$code_dir/general_bash_functions/environment.sh"
validate_cpus "${1:-}"


# define arguments
cores=$1
profiles_dir=$2

# input fasta
FAS=$(select_record "$profiles_dir/clusters.txt")
[[ -s $FAS ]] || { echo "missing cluster FASTA: $FAS" >&2; exit 1; }
activate_environment msa
command -v mafft >/dev/null || {
    echo 'optional profile generation requires mafft' >&2
    exit 1
}

# run mafft on fasta file
ALN=$(echo $FAS | sed 's/.fas/.aln/')
mafft --auto --thread $cores $FAS > $ALN

# run hmmbuild on aligned fasta file to produce profile
software="$HOME/software"
hmmbuild="$software/hmmer-3.4/src/hmmbuild"
HMM=$(echo $ALN | sed 's/.aln/.hmm/')

# if a protein cluster is only composed of one protein use fasta file
if [ -s "$ALN" ]; then
  $hmmbuild --amino --cpu $cores $HMM $ALN
else
  $hmmbuild --amino --cpu $cores $HMM $FAS
fi

# check if hmm file was created and has content
if [ ! -s "$HMM" ]; then
    echo $HMM >> $profiles_dir/errors.txt
    exit 1
else
    echo "profile complete: $HMM"
fi
