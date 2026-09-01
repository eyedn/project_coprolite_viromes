#!/bin/bash

###############################################################################
#       Aydin Karatas
#		Project Coprolite Viromes
#		get_biom.sh 
###############################################################################
#$ -cwd
#$ -N mpa
#$ -o /u/scratch/a/ayd1n/joblogs/sourcetracker/
#$ -j y
#$ -l h_data=8G,h_rt=24:00:00
#$ -pe shared 16

# to run: qsub -t 1-$(ls -d /u/scratch/b/bwknowle/project_coprolite_viromes_sourcetracker/reads/*_fastq_clean | wc -l) get_biom.sh

set -euo pipefail
source /u/local/Modules/default/init/modules.sh
module purge
ml bowtie2/2.4.2
ml anaconda3
conda activate mpa

cd /u/scratch/b/bwknowle/project_coprolite_viromes_sourcetracker
mkdir -p sourcetracker

# pick the nth directory
readarray -t dirs < <(ls -d reads/*_fastq_clean)
i="${dirs[$((SGE_TASK_ID-1))]}"

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
# After all MetaPhlAn jobs have completed
###############################################################################

# conda activate mpa

# # Merge MetaPhlAn profiles
# merge_metaphlan_tables.py *_fastq_clean_profile.out > combined_profile.out

# # Keep only the header row and species-level taxa
# awk 'NR==2 || $1 ~ /\|s__/' combined_profile.out > combined_profile_species_only.tsv

# # Convert relative abundances to integer pseudo-counts
# awk '
# BEGIN {FS=OFS="\t"}
# NR==1 {print; next}
# {
#     for(i=2;i<=NF;i++)
#         $i=int($i*1000+0.5)
#     print
# }
# ' combined_profile_species_only.tsv \
# > combined_profile_species_only_counts.tsv

# # Convert to BIOM
# biom convert \
#     -i combined_profile_species_only_counts.tsv \
#     -o combined_profile_species_only_counts.biom \
#     --table-type="OTU table" \
#     --to-hdf5

# # Check BIOM table
# biom summarize-table \
#     -i combined_profile_species_only_counts.biom

# # Run SourceTracker2

# Create mapping file for Sourcetracker2
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