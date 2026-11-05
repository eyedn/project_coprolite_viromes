#!/bin/bash
###############################################################################
#       Aydin Karatas
#       Project Coprolite Viromes
#       get_biom.sh
###############################################################################


set -euo pipefail
code_dir="${VIROME_CODE_DIR:-$HOME/project_coprolite_viromes}"
source "$code_dir/general_bash_functions/slurm.sh"
source "$code_dir/general_bash_functions/environment.sh"
source_project=/u/scratch/b/bwknowle/project_coprolite_viromes_sourcetracker
cd "$source_project"
shopt -s nullglob
dirs=(reads/*_fastq_clean)
if (( ${#dirs[@]} == 0 )); then
    echo "SourceTracker: no cleaned-read directories in $source_project" >&2
    exit 1
fi
if [[ -z ${SLURM_JOB_ID:-} ]]; then
    export VIROME_CODE_DIR="$code_dir"
    submit_slurm mpa "$SCRATCH/joblogs/sourcetracker" "${#dirs[@]}" \
        16 8 NONE "$code_dir/source_tracking/get_biom.sh" "$@"
    exit $?
fi
validate_cpus 16
array_index=${SLURM_ARRAY_TASK_ID:-}
if [[ ! $array_index =~ ^[1-9][0-9]*$ ]] || \
    (( array_index > ${#dirs[@]} )); then
    echo "SourceTracker: invalid task index: $array_index" >&2
    exit 2
fi
i="${dirs[$((array_index - 1))]}"
activate_environment mpa || {
    echo 'optional mpa environment restoration remains deferred' >&2
    exit 1
}
module load bowtie2/2.4.2 || {
    echo 'optional SourceTracker profiling requires bowtie2/2.4.2' >&2
    exit 1
}
command -v metaphlan >/dev/null || {
    echo 'optional SourceTracker profiling requires metaphlan' >&2
    exit 1
}
mkdir -p sourcetracker

sample="$(basename "$i")"

fastqs="$(
    printf '%s\n' "${i}"/*/*.fastq.gz | paste -sd, -
)"

echo "$sample"
echo "$fastqs"

metaphlan "$fastqs" \
    --verbose \
    --nproc 8 \
    --db_dir /u/scratch/b/bwknowle/mpa_db \
    --input_type fastq \
    --mapout "sourcetracker/${sample}.bowtie2.bz2" \
    -o "sourcetracker/${sample}_profile.out"


###############################################################################
# after all MetaPhlAn jobs have completed
###############################################################################

# conda activate mpa

# # merge MetaPhlAn profiles
# merge_metaphlan_tables.py *_fastq_clean_profile.out > combined_profile.out

# # keep only the header row and species-level taxa
# awk 'NR==2 || $1 ~ /\|s__/' combined_profile.out > combined_profile_species_only.tsv

# # convert relative abundances to integer pseudo-counts
# awk '
# disabled awk: BEGIN {FS=OFS="\t"}
# disabled awk: NR==1 {print; next}
# {
#     for(i=2;i<=NF;i++)
#         $i=int($i*1000+0.5)
#     print
# }
# ' combined_profile_species_only.tsv \
# > combined_profile_species_only_counts.tsv

# # convert to BIOM
# biom convert \
#     -i combined_profile_species_only_counts.tsv \
#     -o combined_profile_species_only_counts.biom \
#     --table-type="OTU table" \
#     --to-hdf5

# # check BIOM table
# biom summarize-table \
#     -i combined_profile_species_only_counts.biom

# # run SourceTracker2

# create mapping file for Sourcetracker2
# (
# echo -e "SampleID\tSourceSink\tEnv"

# head -2 combined_profile.out \
# | tail -1 \
# | tr '\t' '\n' \
# | tail -n +2 \
# | awk '
# /^ind-source_/ {
#     print $1 "\tsource\tIndustrial"
#     next
# }

# /^pre-source_/ {
#     print $1 "\tsource\tNonIndustrial"
#     next
# }

# /^soil_/ {
#     print $1 "\tsource\tSoil"
#     next
# }

# /^pal-/ {
#     print $1 "\tsink\tCoprolite"
#     next
# }
# '
# ) > mapping.txt

# conda activate st2_real

# sourcetracker2 gibbs \
#     -i combined_profile_species_only_counts.biom \
#     -m mapping.txt \
#     -o sourcetracker_output \
#     --source_rarefaction_depth 2500 \
#     --sink_rarefaction_depth 2500 \
#     --jobs 4