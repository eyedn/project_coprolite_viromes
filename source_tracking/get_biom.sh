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
#$ -l h_data=4G,h_rt=24:00:00
#$ -pe shared 8

# to run: qsub -t 1-$(ls -d /u/scratch/b/bwknowle/project_coprolite_viromes/reads/*_fastq_clean | wc -l) get_biom.sh

set -euo pipefail
source /u/local/Modules/default/init/modules.sh
module purge
ml bowtie2/2.4.2
ml anaconda3
conda activate mpa

cd /u/scratch/b/bwknowle/project_coprolite_viromes
mkdir -p sourcetracker

# pick the nth directory
readarray -t dirs < <(ls -d reads/*_fastq_clean)
i="${dirs[$((SGE_TASK_ID-1))]}"

sample="$(basename "$i")"
fastqs="$(
    printf '%s\n' "${i}/"*".fastq.gz" | paste -sd, - 
)"
echo "$sample"

# init run
metaphlan "$fastqs" \
    --verbose \
    --nproc 8 \
    --db_dir /u/scratch/b/bwknowle/mpa_db \
    --input_type fastq \
    --mapout "sourcetracker/${sample}.bowtie2.bz2" \
    -o "sourcetracker/${sample}_profile.out"
    # --biom_format_output

# rerun
# metaphlan "sourcetracker/${sample}.bowtie2.bz2" \
#     --verbose \
#     --nproc 8 \
#     --db_dir /u/scratch/b/bwknowle/mpa_db \
#     --input_type mapout \
#     --sample_id_key "${sample}" \
#     -o "sourcetracker/${sample}_profile.out"
#     # --biom_format_output

## run after above runs
# conda activate st2-np1.19
# for f in *_fastq_clean_profile.out; do; sample=$(basename "$f" "_fastq_clean_profile.out"); out="${f}.renamed"; awk -v s="$sample" 'BEGIN{OFS="\t"} /^#SampleID/ {$1="#"s} {print}' "$f" > "$out"; done
# 
# merge_metaphlan_tables.py *_fastq_clean_profile.out.renamed > combined_profile.out
#
## edit to combined_profile.otu by formatting header with text editing
# 
## filter to species rows (those containing |s__) for species
# awk 'NR==1 || $1 ~ /\|s__/ {print}' combined_profile.otu > combined_profile_species_only.otu
#
## convert abundances to integer counts
# awk 'BEGIN{FS=OFS="\t"} NR==1{print; next} {for(i=2;i<=NF;i++) $i=int($i*1000+0.5); print}' combined_profile_species_only.otu > combined_profile_species_only_counts.otu 
# 
## build biom table
# biom convert -i combined_profile_species_only_counts.otu -o combined_profile_species_only_counts.biom --table-type="OTU table" --to-hdf5
#
## verify biom table
# biom summarize-table -i combined_profile_species_only_counts.biom
#
## run source tracker with --source_rarefaction_depth 2500   --sink_rarefaction_depth 2500 (consistent for out verify step)
# sourcetracker2 gibbs -i combined_profile_species_only_counts.biom -m mapping.txt -o sourcetracker_output/ --source_rarefaction_depth 2500 --sink_rarefaction_depth 2500 --jobs 4